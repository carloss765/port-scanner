package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"os"
	"sort"
	"sync"
	"time"
)

type ScanResult struct {
	Host       string `json:"host"`
	StartPort  int    `json:"start_port"`
	EndPort    int    `json:"end_port"`
	OpenPorts  []int  `json:"open_ports"`
	ScanTimeMs int64  `json:"scan_time_ms"`
}

func worker(wg *sync.WaitGroup, ports <-chan int, host string, results chan<- int, verbose bool) {
	defer wg.Done()

	for port := range ports {
		address := fmt.Sprintf("%s:%d", host, port)
		conn, err := net.DialTimeout("tcp", address, 500*time.Millisecond)
		if err == nil {
			conn.Close()
			fmt.Fprintf(os.Stderr, "[OPEN]   Port %d is open\n", port)
			results <- port
		} else if verbose {
			fmt.Fprintf(os.Stderr, "[CLOSED] Port %d is closed\n", port)
		}
	}
}

func main() {
	host := flag.String("host", "127.0.0.1", "Host to scan")
	start := flag.Int("start", 1, "Start port")
	end := flag.Int("end", 1024, "End port")
	workers := flag.Int("workers", 100, "Number of concurrent workers")
	verbose := flag.Bool("verbose", true, "Show closed ports in output")

	flag.Parse()

	fmt.Fprintf(os.Stderr, "[INFO]   Starting scan on %s ports %d-%d (verbose=%v)\n", *host, *start, *end, *verbose)

	startTime := time.Now()

	ports := make(chan int)
	results := make(chan int)

	var wg sync.WaitGroup

	for i := 1; i <= *workers; i++ {
		wg.Add(1)
		go worker(&wg, ports, *host, results, *verbose)
	}

	go func() {
		for port := *start; port <= *end; port++ {
			ports <- port
		}
		close(ports)
	}()

	go func() {
		wg.Wait()
		close(results)
	}()

	openPorts := make([]int, 0)
	for port := range results {
		openPorts = append(openPorts, port)
	}

	sort.Ints(openPorts)

	elapsed := time.Since(startTime)
	scanTime := elapsed.Milliseconds()

	fmt.Fprintf(os.Stderr, "[INFO]   Scan complete. Found %d open port(s) in %dms\n", len(openPorts), scanTime)

	result := ScanResult{
		Host:       *host,
		StartPort:  *start,
		EndPort:    *end,
		OpenPorts:  openPorts,
		ScanTimeMs: scanTime,
	}
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	encoder.Encode(result)
}
