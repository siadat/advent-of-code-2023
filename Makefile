all:
	zig build-exe ./day1/main.zig
	cat ./day1/input.txt | time -v ./main ./day1/main.zig

clean:
	rm -f ./main
	rm -f ./main.o
