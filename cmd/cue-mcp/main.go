package main

import (
	"log"
	"os"

	"github.com/fatb4f/contract.cuemod/runtime/internal/cuemcp"
)

func main() {
	root := os.Getenv("CUE_CONTRACT_ROOT")
	if root == "" {
		root = "/home/_404/src/contract.cuemod"
	}
	if err := cuemcp.Serve(root); err != nil {
		log.Fatal(err)
	}
}
