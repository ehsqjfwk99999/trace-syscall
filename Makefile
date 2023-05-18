all:
	gcc -o open open.c
format:
	clang-format --style=llvm -i open.c
clean:
	rm open
