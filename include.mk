npm-root != npm root
npm-prefix := ${npm-lib:%=${npm-root}/%} \
	${npm-lib:%=${npm-root-dir}/../../%}
prefix := ${pwd} /usr/local
XCOMPILER := -Wall -Wextra -Wpedantic
CFLAGS := -g ${npm-prefix:%=-I%/include}
# LDFLAGS  :=  ${prefix:%=-Wl,-rpath,%/lib}
# 	   ${npm-prefix:%=-L%/lib} \
LDFLAGS	:= ${prefix:%=-L%/lib} \
	   ${npm-prefix:%=-L%/lib}
