// RUN: %clang -### -x hip -nogpulib -nogpuinc --gpu-max-threads-per-block=1024 %s 2>&1 | FileCheck %s

// Check that there are commands for both host- and device-side compilations.
//
// CHECK: "-cc1" {{.*}} "-fcuda-is-device"
// CHECK-SAME: "--gpu-max-threads-per-block=1024"

// RUN: %clang -### -nogpuinc -nogpulib -fgpu-allow-device-init \
// RUN:   %s 2>&1 | FileCheck -check-prefix=DEVINIT %s
// DEVINIT: "-cc1" {{.*}}"-fgpu-allow-device-init"
// DEVINIT: "-cc1" {{.*}}"-fgpu-allow-device-init"

// Check -fgpu-default-stream=per-thread.
// RUN: %clang -### -nogpuinc -nogpulib -fgpu-default-stream=per-thread \
// RUN:   %s -save-temps 2>&1 | FileCheck -check-prefix=PTH %s
// PTH: "-cc1"{{.*}} "-E" {{.*}}"-fgpu-default-stream=per-thread"
// PTH: "-cc1"{{.*}} "-fgpu-default-stream=per-thread" {{.*}}"-x" "hip-cpp-output"
// PTH: "-cc1"{{.*}} "-E" {{.*}}"-fgpu-default-stream=per-thread"
// PTH: "-cc1"{{.*}} "-fgpu-default-stream=per-thread" {{.*}}"-x" "hip-cpp-output"

// Check -mprintf-kind=hostcall
// RUN: %clang -### -nogpulib -nogpuinc --target=x86_64-unknown-linux-gnu -mprintf-kind=hostcall  %s -save-temps 2>&1 | FileCheck -check-prefix=HOSTC %s
// HOSTC: "-cc1" "-triple" "amdgcn-amd-amdhsa"{{.*}}"-mprintf-kind=hostcall" "-Werror=format-invalid-specifier"{{.*}}"-E" {{.*}}
// HOSTC: "-cc1" "-triple" "amdgcn-amd-amdhsa"{{.*}} "-mprintf-kind=hostcall" "-Werror=format-invalid-specifier" {{.*}}"-x" "hip-cpp-output"
// HOSTC: "-cc1" "-triple" "amdgcn-amd-amdhsa"{{.*}} "-mprintf-kind=hostcall" "-Werror=format-invalid-specifier" {{.*}}"-x" "ir"
// HOSTC: "-cc1" "-triple" "x86_64-unknown-linux-gnu"{{.*}} "-E" {{.*}}
// HOSTC: "-cc1" "-triple" "x86_64-unknown-linux-gnu"{{.*}}"-x" "ir"

// Check -mprintf-kind=buffered
// RUN: %clang -### -nogpulib -nogpuinc --target=x86_64-unknown-linux-gnu -mprintf-kind=buffered  %s -save-temps 2>&1 | FileCheck -check-prefix=BUFF %s
// BUFF: "-cc1" "-triple" "amdgcn-amd-amdhsa"{{.*}}"-mprintf-kind=buffered" "-Werror=format-invalid-specifier"{{.*}}"-E" {{.*}}
// BUFF: "-cc1" "-triple" "amdgcn-amd-amdhsa"{{.*}} "-mprintf-kind=buffered" "-Werror=format-invalid-specifier" {{.*}}"-x" "hip-cpp-output"
// BUFF: "-cc1" "-triple" "amdgcn-amd-amdhsa"{{.*}} "-mprintf-kind=buffered" "-Werror=format-invalid-specifier" {{.*}}"-x" "ir"
// BUFF: "-cc1" "-triple" "x86_64-unknown-linux-gnu"{{.*}} "-E" {{.*}}
// BUFF: "-cc1" "-triple" "x86_64-unknown-linux-gnu"{{.*}}"-x" "ir"

// RUN: %clang -### -x hip -nogpulib -nogpuinc --target=x86_64-pc-windows-msvc -fms-extensions \
// RUN:   -mllvm -amdgpu-early-inline-all=true  %s 2>&1 | \
// RUN:   FileCheck -check-prefix=MLLVM %s
// MLLVM-NOT: "-mllvm"{{.*}}"-amdgpu-early-inline-all=true"{{.*}}"-mllvm"{{.*}}"-amdgpu-early-inline-all=true"

// RUN: %clang -### -Xarch_device -g -nogpulib -nogpuinc --cuda-gpu-arch=gfx900 \
// RUN:   -Xarch_device -fcf-protection=branch -Xarch_device -mllvm=--inline-threshold=100 \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=DEV %s
// DEV: "-cc1"{{.*}} "-fcuda-is-device" {{.*}} "-debug-info-kind={{.*}}" {{.*}} "-fcf-protection=branch" {{.*}}"-mllvm" "--inline-threshold=100"
// DEV: "-cc1"{{.*}} "-fcuda-is-device" {{.*}} "-debug-info-kind={{.*}}" {{.*}} "-fcf-protection=branch" {{.*}}"-mllvm" "--inline-threshold=100"
// DEV-NOT: clang{{.*}} {{.*}} "-debug-info-kind={{.*}}"

// RUN: %clang -### -Xarch_host -g -nogpulib -nogpuinc --cuda-gpu-arch=gfx900 \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=HOST %s
// HOST-NOT: "-fcuda-is-device" {{.*}} "-debug-info-kind={{.*}}"
// HOST-NOT: "-fcuda-is-device" {{.*}} "-debug-info-kind={{.*}}"
// HOST: clang{{.*}} "-debug-info-kind={{.*}}"

// RUN: %clang -### -nogpuinc -nogpulib -munsafe-fp-atomics \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=UNSAFE-FP-ATOMICS %s
// UNSAFE-FP-ATOMICS: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fatomic-ignore-denormal-mode"

// RUN: %clang -### -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=DEFAULT-UNSAFE-FP-ATOMICS %s
// DEFAULT-UNSAFE-FP-ATOMICS-NOT: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fatomic-ignore-denormal-mode"

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -fgpu-exclude-wrong-side-overloads \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=FIX-OVERLOAD %s
// FIX-OVERLOAD: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fgpu-exclude-wrong-side-overloads" "-fgpu-defer-diag"
// FIX-OVERLOAD: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-fgpu-exclude-wrong-side-overloads" "-fgpu-defer-diag"

// Check -mconstructor-aliases is not passed to device compilation.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=CTA %s
// CTA: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-mconstructor-aliases"
// CTA-NOT: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-mconstructor-aliases"

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx906 -fgpu-inline-threshold=1000 %s 2>&1 | FileCheck -check-prefix=THRESH %s
// THRESH: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-mllvm" "-inline-threshold=1000"
// THRESH-NOT: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-inline-threshold=1000"

// Check -foffload-lto=thin translated correctly.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 -foffload-lto=thin -fwhole-program-vtables %s 2>&1 \
// RUN:   | FileCheck -check-prefix=HIPTHINLTO %s

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 -fgpu-rdc -foffload-lto=thin -fwhole-program-vtables %s 2>&1 \
// RUN:   | FileCheck -check-prefix=HIPTHINLTO %s

// Ensure we don't error about -fwhole-program-vtables for the non-device offload compile.
// HIPTHINLTO-NOT: error: invalid argument '-fwhole-program-vtables' only allowed with '-flto'
// HIPTHINLTO-NOT: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-flto-unit"
// HIPTHINLTO: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-flto=thin" "-flto-unit" {{.*}} "-fwhole-program-vtables"
// HIPTHINLTO-NOT: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-flto-unit"
// HIPTHINLTO: lld{{.*}}"-plugin-opt=mcpu=gfx906" "-plugin-opt=thinlto" "-plugin-opt=-force-import-all"

// Check that -flto=thin is handled correctly, particularly with -fwhole-program-vtables.
//
// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 -flto=thin -fwhole-program-vtables %s 2>&1 \
// RUN:   | FileCheck -check-prefix=THINLTO %s

// Ensure we don't error about -fwhole-program-vtables for the device offload compile. We should
// drop -fwhole-program-vtables for the device offload compile and pass it through for the
// non-device offload compile along with -flto=thin.
// THINLTO-NOT: error: invalid argument '-fwhole-program-vtables' only allowed with '-flto'
// THINLTO-NOT: "-cc1"{{.*}}" "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fwhole-program-vtables"
// THINLTO: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-flto=thin" {{.*}} "-fwhole-program-vtables"
// THINLTO-NOT: "-cc1"{{.*}}" "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fwhole-program-vtables"

// Check -fopenmp=libomp is allowed with HIP but -fopenmp-targets= is not allowed.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx906 -fopenmp=libomp %s 2>&1 | FileCheck -check-prefix=OMP %s
// OMP-NOT: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fopenmp"
// OMP: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-fopenmp"

// Check -Xoffload-linker option is passed to lld.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 -fgpu-rdc -Xoffload-linker --build-id=md5 %s 2>&1 \
// RUN:   | FileCheck -check-prefix=OFL-LINK %s
// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 -Xoffload-linker --build-id=md5 %s 2>&1 \
// RUN:   | FileCheck -check-prefix=OFL-LINK %s
// OFL-LINK: lld{{.*}}"--build-id=md5"

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx906 -fhip-kernel-arg-name %s 2>&1 \
// RUN:   | FileCheck -check-prefix=KAN %s
// KAN: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fhip-kernel-arg-name"

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx906 %s 2>&1 \
// RUN:   | FileCheck -check-prefix=KANNEG %s
// KANNEG-NOT: "-fhip-kernel-arg-name"

// RUN: %clang -### -nogpuinc -nogpulib -mno-amdgpu-ieee -mamdgpu-ieee \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefix=IEEE-ON %s
// IEEE-ON-NOT: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-m{{(no-)?}}amdgpu-ieee"

// RUN: %clang -### -nogpuinc -nogpulib -mamdgpu-ieee -mno-amdgpu-ieee -ffast-math \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefixes=IEEE-OFF %s
// IEEE-OFF: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-mno-amdgpu-ieee"

// RUN: %clang -### -nogpuinc -nogpulib -mamdgpu-ieee -mno-amdgpu-ieee -ffast-math \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefixes=IEEE-OFF-NEG %s
// IEEE-OFF-NEG-NOT: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-mamdgpu-ieee"

// Check -fno-hip-fp32-correctly-rounded-divide-sqrt is passed to -cc1 but
// (default) -fhip-fp32-correctly-rounded-divide-sqrt is not.

// RUN: %clang -### -nogpuinc -nogpulib -fno-hip-fp32-correctly-rounded-divide-sqrt \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefixes=NOCRDS %s
// NOCRDS: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fno-hip-fp32-correctly-rounded-divide-sqrt"

// RUN: %clang -### -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefixes=CRDS %s
// CRDS-NOT: "-f{{(no-)?}}hip-fp32-correctly-rounded-divide-sqrt"

// RUN: %clang -### -nogpuinc -nogpulib -fhip-fp32-correctly-rounded-divide-sqrt \
// RUN:   --cuda-gpu-arch=gfx906  %s 2>&1 | FileCheck -check-prefixes=CRDS %s
// CRDS-NOT: "-f{{(no-)?}}hip-fp32-correctly-rounded-divide-sqrt"

// Check -fgpu-approx-transcendentals is passed to clang -cc1 but
// (default) -fno-gpu-approx-transcendentals is not.
// -ffast-math implies -fgpu-approx-transcendentals, which can be overridden
// by -fno-gpu-approx-transcendentals.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -fgpu-approx-transcendentals \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=APPROX %s

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -ffast-math \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=APPROX %s

// APPROX: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fgpu-approx-transcendentals"
// APPROX: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-fgpu-approx-transcendentals"

// RUN: %clang -### -nogpuinc -nogpulib -fno-gpu-approx-transcendentals \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=NOAPPROX %s

// RUN: %clang -### -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=NOAPPROX %s

// RUN: %clang -### -nogpuinc -nogpulib -ffast-math -fno-fast-math \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=NOAPPROX %s

// RUN: %clang -### -nogpuinc -nogpulib -ffast-math -fno-gpu-approx-transcendentals \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=NOAPPROX %s

// NOAPPROX-NOT: "-f{{(no-)?}}gpu-approx-transcendentals"

// Check no warnings for -fgpu-approx-transcendentals.

// RUN: %clang -fdriver-only -Werror --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -fgpu-approx-transcendentals \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | count 0

// RUN: %clang -fdriver-only -Werror --target=x86_64-unknown-linux-gnu -nostdinc -nostdlib -fgpu-approx-transcendentals \
// RUN:   -x c++ %s 2>&1 | count 0
/ Check -fno-offload-uniform-block is passed to clang -cc1 but
// (default) -fno-offload-uniform-block is not.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -fno-offload-uniform-block \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=NOUNIBLK %s

// NOUNIBLK: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-fno-offload-uniform-block"
// NOUNIBLK: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-fno-offload-uniform-block"

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -foffload-uniform-block \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=UNIBLK %s

// UNIBLK: "-cc1"{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-foffload-uniform-block"
// UNIBLK: "-cc1"{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-foffload-uniform-block"

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=DEFUNIBLK %s

// DEFUNIBLK-NOT: "-f{{(no-)?}}offload-uniform-block"

// Check no warnings for -f[no-]offload-uniform-block.

// RUN: %clang -fdriver-only -c -Werror --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib -fno-offload-uniform-block \
// RUN:   -foffload-uniform-block --cuda-gpu-arch=gfx906 %s 2>&1 | count 0

// Check -Werror=atomic-alignment is passed for amdpu by default.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 %s 2>&1 | FileCheck -check-prefix=WARN-ATOMIC %s
// WARN-ATOMIC: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-Werror=atomic-alignment"
// WARN-ATOMIC-NOT: clang{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-Werror=atomic-alignment"

// Check the default -Werror=atomic-alignment can be overridden.

// RUN: %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --cuda-gpu-arch=gfx906 -Xarch_device -Wno-error=atomic-alignment %s \
// RUN:   2>&1 | FileCheck -check-prefix=NO-WARN-ATOMIC %s
// NO-WARN-ATOMIC: clang{{.*}} "-triple" "amdgcn-amd-amdhsa" {{.*}} "-Werror=atomic-alignment" {{.*}} "-Wno-error=atomic-alignment"
// NO-WARN-ATOMIC-NOT: clang{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-Werror=atomic-alignment"
// NO-WARN-ATOMIC-NOT: clang{{.*}} "-triple" "x86_64-unknown-linux-gnu" {{.*}} "-Wno-error=atomic-alignment"

// Check --offload-compress --offload-jobs=N does not cause warning.
// RUN: %clang -### -Werror --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx1100 --offload-compress --offload-host-only -M %s \
// RUN:   --offload-jobs=4

// Check --offload-jobs=N option.

// RUN: %clang -### -Werror --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx1100 --offload-new-driver --offload-jobs=4 %s 2>&1 | \
// RUN:   FileCheck -check-prefix=JOBS %s
// JOBS: clang-linker-wrapper{{.*}} "--wrapper-jobs=4"

// RUN: not %clang -### --target=x86_64-unknown-linux-gnu -nogpuinc -nogpulib \
// RUN:   --offload-arch=gfx1100 --offload-new-driver --offload-jobs=0x4 %s 2>&1 | \
// RUN:   FileCheck -check-prefix=INVJOBS %s
// INVJOBS: clang: error: invalid integral value '0x4' in '--offload-jobs=0x4'
