// Command wordcount counts words read from stdin.
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	s := bufio.NewScanner(os.Stdin)
	s.Split(bufio.ScanWords)
	n := 0
	for s.Scan() {
		n++
	}
	fmt.Println(n)
}
