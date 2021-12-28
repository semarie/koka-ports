# $OpenBSD$

COMMENT =	strongly typed functional-style language with effect types

DISTNAME =	koka-${V}
V =		2.3.8

MIMALLOC_CID =	43ed8510065514a959852d95000f8ab08b535ceb

CATEGORIES =	lang

HOMEPAGE =	https://koka-lang.github.io/

MASTER_SITES =	https://github.com/koka-lang/koka/archive/v${V}/
MASTER_SITES0 =	https://github.com/microsoft/mimalloc/archive/

DISTFILES +=	${DISTNAME}${EXTRACT_SUFX} \
		mimalloc-${MIMALLOC_CID:C/(........).*/\1/}${EXTRACT_SUFX}{${MIMALLOC_CID}${EXTRACT_SUFX}}:0

# Apache 2.0 (and MIT for mimalloc)
PERMIT_PACKAGE =	Yes

WANTLIB +=	c ffi gmp iconv m pthread util

USE_WXNEEDED =	Yes

LIB_DEPENDS +=		converters/libiconv \
			devel/gmp,-main \
			devel/libffi

BUILD_DEPENDS +=	devel/pcre2
RUN_DEPENDS +=		devel/pcre2

MODULES +=		devel/cabal
MODCABAL_STEM =		koka
MODCABAL_VERSION =	${V}

# cabal new-update && cabal new-configure && \
# 	cabal-bundler -p ./dist-newstyle/cache/plan.json --openbsd koka

# koka (without testsuite)
MODCABAL_MANIFEST = \
	alex		3.2.6	0	\
	isocline	1.0.6	0	\

# XXX figure why cabal fails to build koka-test
# rejecting: splitmix:*test (cyclic dependencies; conflict set: random splitmix)
NO_TEST =	Yes

# XXX figure if useful or not
#KK_C_COMPILER-amd64 =	clang
#KK_C_COMPILER =	${KK_C_COMPILER-${MACHINE_ARCH}
#SUBST_VARS +=		KK_C_COMPILER

post-extract:
#	install mimalloc inside kklib
	test -d ${WRKSRC}/kklib/mimalloc && rmdir ${WRKSRC}/kklib/mimalloc
	mv ${WRKDIR}/mimalloc-${MIMALLOC_CID} \
		${WRKSRC}/kklib/mimalloc
	cd ${WRKSRC}/kklib && rm -rf -- \
		mimalloc/{bin,cmake,doc,docs,ide,test} \
		mimalloc/{azure-pipelines.yml,CMakeLists.txt}
#	remove pre-generated file
	rm ${WRKSRC}/src/Syntax/Lexer.hs

pre-patch:
	sed -i -e 's/-j8//' ${WRKSRC}/koka.cabal

post-patch:
	${SUBST_CMD} ${WRKSRC}/src/Common/File.hs

# build the compiler (koka) and bundle tool
do-build:
#	build koka
	${_MODCABAL_BUILD_TARGET}
#	run koka, to build util_bundle
	cd ${WRKBUILD} && \
		${SETENV} ${MAKE_ENV} ${MODCABAL_BUILT_EXECUTABLE_koka} \
			${WRKSRC}/util/bundle.kk -o ${WRKBUILD}/util_bundle

do-install:
#	prebuild koka libraries and install them
	cd ${WRKBUILD} && ${SETENV} ${MAKE_ENV} ${WRKBUILD}/util_bundle \
		--install \
		--prefix=${PREFIX} \
		--koka=${MODCABAL_BUILT_EXECUTABLE_koka}
#	patched files cleanup
	find ${PREFIX} -type f -name '*${PATCHORIG}' -delete
#	replace libpcre2-8.a by link to devel/pcre2
	ln -fs ${LOCALBASE}/lib/libpcre2-8.a ${PREFIX}/lib/koka/v${V}/clang-debug
	ln -fs ${LOCALBASE}/lib/libpcre2-8.a ${PREFIX}/lib/koka/v${V}/clang-drelease
	ln -fs ${LOCALBASE}/lib/libpcre2-8.a ${PREFIX}/lib/koka/v${V}/clang-release

.include <bsd.port.mk>
