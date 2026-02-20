package main

import (
	"fmt"
	"net" // Managen network connections
	"sync"
	"time"
)

func scanPort(wg *sync.WaitGroup, host string, port int) {
	defer wg.Done()

	address := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", address, 500*time.Millisecond) // try connect to remote service
	if err != nil {
		fmt.Printf("Puerto %d cerrado o filtrado (%v)\n", port, err) //? fails optional for user
		return
	}
	conn.Close()
	fmt.Printf("Puerto %d abierto\n", port)
}

func main() {
	host := "scanme.nmap.org"
	var wg sync.WaitGroup

	for port := 1; port <= 100; port++ {
		wg.Add(1)
		go scanPort(&wg, host, port) // gorutine
	}
	wg.Wait()
}
