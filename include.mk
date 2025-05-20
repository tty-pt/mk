npm-prefix := ${npm-lib:%=${npm-root}/%} \
	${npm-lib:%=${npm-root-dir}/../../%}
prefix := ${pwd} /usr/local
CFLAGS := -g -Wall -Wextra -Wpedantic \
	  ${npm-prefix:%=-I%/include}
LDFLAGS	:= ${prefix:%=-L%/lib} \
	   ${npm-prefix:%=-L%/lib} \
	   ${npm-prefix:%=-Wl,-rpath,%/lib}
