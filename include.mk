pwd != pwd
npm-root != npm root
npm-root-dir != dirname ${npm-root}
prefix := ${pwd} \
	  ${npm-lib:%=${npm-root}/%} \
	  ${npm-lib:%=${npm-root-dir}/../../%} \
	  /usr/local
WARN := -Wall -Wextra -Wpedantic
CFLAGS += -g ${prefix:%=-I%/include}
LDFLAGS	+= ${prefix:%=-L%/lib} ${prefix:%=-Wl,-rpath,%/lib}
