import ./make-test-python.nix ({ pkgs, ... }: let
  example-source-c = pkgs.writeText "example-source-c.c" ''
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    int main() {
      printf("executing...\n");
      char data[128];
      memset(data, '\0', 128);
      if (fgets(data, sizeof(data)/sizeof(data[0]), stdin) != NULL) {
        if (data[0] == 'a' && data[1] == 'b')
          return 1;
          //abort();
        else
          printf("valid data\n");
        return 0;
      }
      return 1;
    }
  '';

  example-source-cpp = pkgs.writeText "example-source-cpp.cpp" ''
    #include <array>
    #include <cstdlib>
    #include <iostream>
    int main() {
      std::cout << "executing...\n";
      std::array<char, 128> data{};
      if (std::fgets(data.data(), data.size(), stdin) != nullptr) {
        if (data[0] == 'a' && data[1] == 'b')
          std::abort();
        else
          std::cout << "valid data\n";
        return 0;
      }
      return 1;
    }
  '';


in
{
  name = "aflplusplus";
  meta.maintainers = with pkgs.lib.maintainers; [ mindavi ];

  nodes.machine = { pkgs, ... }: {
    imports = [ ./common/user-account.nix ];
    environment.systemPackages = with pkgs; [
      aflplusplus
      gcc  # would just supplying binutils be enough?
    ];
    virtualisation.cores = 2;
  };

  testScript = ''
    machine.wait_for_unit("basic.target")

    #with subtest("Setup afl with afl-system-config"):
    #  machine.succeed(
    #      "afl-system-config",
    #  )

    with subtest("Build c binary with aflplusplus"):
      machine.succeed(
        "afl-gcc ${example-source-c} -o c-bin-gcc",
        "afl-clang-fast ${example-source-c} -o c-bin-clang"
      )

    with subtest("Build c++ binary with aflplusplus"):
      machine.succeed(
        "afl-g++ ${example-source-cpp} -o cpp-bin-g++",
        "afl-clang-fast++ ${example-source-cpp} -o cpp-bin-clang++"
      )

    with subtest("Create corpus dir"):
      machine.succeed(
        "mkdir corpus",
        "echo hello > corpus/empty.txt"
      )

    with subtest("Verify built binaries are working"):
      machine.succeed(
        "cat corpus/empty.txt | ./c-bin-gcc",
        "cat corpus/empty.txt | ./c-bin-clang",
        "cat corpus/empty.txt | ./cpp-bin-g++",
        "cat corpus/empty.txt | ./cpp-bin-clang++"
      )

    with subtest("Run afl-fuzz on c-bin"):
      machine.succeed(
        # -V is how long the test should run for
        "AFL_NO_UI=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 afl-fuzz -i corpus -o output-c ./c-bin-gcc -V 10"
      )
  '';
})
