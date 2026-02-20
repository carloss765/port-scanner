package main

import (
	"flag"
	"fmt"
	"net" // Managen network connections
	"sync"
	"time"
)

func worker(wg *sync.WaitGroup, ports <-chan int, host string, results chan<- int) {
	defer wg.Done()

	for port := range ports {
		address := fmt.Sprintf("%s:%d", host, port)
		conn, err := net.DialTimeout("tcp", address, 500*time.Millisecond) // try connect to remote service
		if err == nil {
			conn.Close()
			results <- port
		}
	}
}

func main() {
	host := flag.String("host", "127.0.0.1", "Host to scan") // flags for agility in terminal
	start := flag.Int("start", 1, "Puerto inicial")
	end := flag.Int("end", 1024, "Puerto final")
	workers := flag.Int("workers", 100, "Cantidad de workers")

	flag.Parse()

	startTime := time.Now()

	ports := make(chan int, *workers)
	results := make(chan int)

	var wg sync.WaitGroup

	for i := 1; i <= *workers; i++ { // create workers
		wg.Add(1)
		go worker(&wg, ports, *host, results)
	}

	go func() { // scann ports
		for port := *start; port <= *end; port++ {
			ports <- port
		}
		close(ports)
	}()

	go func() { // close results when all workers are done
		wg.Wait()
		close(results)
	}()

	fmt.Printf("Escaneando...")

	for port := range results {
		fmt.Printf("Puerto %d esta abierto\n", port)
	}

	elapsed := time.Since(startTime)
	fmt.Printf("Tiempo total: %s\n", elapsed)
}
