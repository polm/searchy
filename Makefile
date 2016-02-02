all: src/search.ls
	lsc -c -o lib src/

clean:
	rm -f lib/*
