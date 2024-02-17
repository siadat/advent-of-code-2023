run-day2:
	zig test ./day2/main.zig
	cat ./day2/input.txt | zig run ./day2/main.zig
run-dayx:
	zig build-exe ./day1/main.zig
	cat ./day1/input.txt | time -v ./main ./day1/main.zig

clean:
	rm -f ./main
	rm -f ./main.o
