# $OpenBSD$

COMMENT =	strongly typed functional-style language with effect types

DISTNAME =	koka-${V}
V =		2.3.6

MIMALLOC_CID =	67e8df6a5c9a503d04d7b14a3a01a5e66f758c98

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

MODULES +=		devel/cabal
MODCABAL_STEM =		koka
MODCABAL_VERSION =	${V}

# cabal new-update && cabal new-configure && \
# 	cabal-bundler -p ./dist-newstyle/cache/plan.json --openbsd koka

# koka (without testsuite)
#MODCABAL_MANIFEST = \
#	alex		3.2.6	0	\
#	isocline	1.0.5	0	\

# koka (with testsuite)
MODCABAL_MANIFEST = \
	HUnit		1.6.2.0	0	\
	QuickCheck	2.14.2	0	\
	alex		3.2.6	0	\
	ansi-terminal	0.11.1	0	\
	call-stack	0.4.0	0	\
	clock		0.8.2	0	\
	colour		2.3.6	0	\
	extra		1.7.10	0	\
	hspec		2.9.4	0	\
	hspec-core	2.9.4	0	\
	hspec-discover	2.9.4	0	\
	hspec-expectations	0.8.2	0	\
	isocline	1.0.5	0	\
	json		0.10	1	\
	primitive	0.7.3.0	0	\
	quickcheck-io	0.2.0	0	\
	random		1.2.1	0	\
	regex-base	0.94.0.2	0	\
	regex-compat-tdfa 0.95.1.4	0	\
	regex-tdfa	1.3.1.1	1	\
	setenv		0.1.1.3	1	\
	splitmix	0.1.0.4	0	\
	syb		0.7.2.1	0	\
	tf-random	0.5	0	\

# XXX figure why cabal fails to build koka-test
# rejecting: splitmix:*test (cyclic dependencies; conflict set: random splitmix)
NO_TEST =	Yes

# XXX figure if useful or not
#KK_C_COMPILER-amd64 =	clang
#KK_C_COMPILER =	${KK_C_COMPILER-${MACHINE_ARCH}
#SUBST_VARS +=		KK_C_COMPILER

# install mimalloc inside kklib
post-extract:
	test -d ${WRKSRC}/kklib/mimalloc && rmdir ${WRKSRC}/kklib/mimalloc
	mv ${WRKDIR}/mimalloc-${MIMALLOC_CID} \
		${WRKSRC}/kklib/mimalloc

# build the compiler (koka) and bundle tool
do-build:
#	build koka
	${_MODCABAL_BUILD_TARGET}
#	run koka, to build util_bundle
	cd ${WRKBUILD} && \
		${SETENV} ${MAKE_ENV} ${MODCABAL_BUILT_EXECUTABLE_koka} \
			${WRKSRC}/util/bundle.kk -o ${WRKBUILD}/util_bundle

# prebuild koka libraries and install them
do-install:
	cd ${WRKBUILD} && ${WRKBUILD}/util_bundle \
		--install \
		--prefix=${PREFIX} \
		--koka=${MODCABAL_BUILT_EXECUTABLE_koka}
	find ${PREFIX} -type f -name '*${PATCHORIG}' -delete

.include <bsd.port.mk>
