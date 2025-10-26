#include <gtest/gtest.h>
#include "math_operations.h" // if you want to test functions from your project

TEST(HelloWorld, Basic) {
  EXPECT_EQ(1 + 1, 2);
}

TEST(MathOperations, Add) {
  // assuming you have int add(int a, int b) in math_operations.h/.cpp
  EXPECT_EQ(add(2, 3), 5);
}