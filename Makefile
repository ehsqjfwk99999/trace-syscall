all:
	gcc -o open_close open_close.c
format:
	clang-format --style=llvm -i open_close.c
clean:
	rm open_close
