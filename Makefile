run-day3:
	zig test ./day3/main.zig
	cat ./day3/input.txt | zig run ./day3/main.zig

run-day2:
	zig test ./day2/main.zig
	cat ./day2/input.txt | zig run ./day2/main.zig

run-day1:
	zig build-exe ./day1/main.zig
	cat ./day1/input.txt | time -v ./main ./day1/main.zig

all: run-day1 run-day2
	@echo "All done"

clean:
	rm -f ./main
	rm -f ./main.o
