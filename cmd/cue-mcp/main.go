package main

import (
	"log"
	"os"

	"github.com/fatb4f/contract.cuemod/runtime/internal/cuemcp"
)

func main() {
	root := os.Getenv("CUE_CONTRACT_ROOT")
	if root == "" {
		var err error
		root, err = os.Getwd()
		if err != nil {
			log.Fatal(err)
		}
	}
	if err := cuemcp.Serve(root); err != nil {
		log.Fatal(err)
	}
}
