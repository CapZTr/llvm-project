//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// <sstream>

// template <class charT, class traits = char_traits<charT>, class Allocator = allocator<charT> >
// class basic_ostringstream

// basic_ostringstream(basic_ostringstream&& rhs);

// XFAIL: FROZEN-CXX03-HEADERS-FIXME

#include <sstream>
#include <cassert>

#include "operator_hijacker.h"
#include "test_macros.h"

int main(int, char**)
{
    {
        std::ostringstream ss0(" 123 456");
        std::ostringstream ss(std::move(ss0));
        assert(ss.rdbuf() != nullptr);
        assert(ss.good());
        assert(ss.str() == " 123 456");
        int i = 234;
        ss << i << ' ' << 567;
        assert(ss.str() == "234 5676");
    }
    {
      std::basic_ostringstream<char, std::char_traits<char>, operator_hijacker_allocator<char> > ss0(" 123 456");
      std::basic_ostringstream<char, std::char_traits<char>, operator_hijacker_allocator<char> > ss(std::move(ss0));
      assert(ss.rdbuf() != nullptr);
      assert(ss.good());
      assert(ss.str() == " 123 456");
      int i = 234;
      ss << i << ' ' << 567;
      assert(ss.str() == "234 5676");
    }
#ifndef TEST_HAS_NO_WIDE_CHARACTERS
    {
        std::wostringstream ss0(L" 123 456");
        std::wostringstream ss(std::move(ss0));
        assert(ss.rdbuf() != nullptr);
        assert(ss.good());
        assert(ss.str() == L" 123 456");
        int i = 234;
        ss << i << ' ' << 567;
        assert(ss.str() == L"234 5676");
    }
    {
      std::basic_ostringstream<wchar_t, std::char_traits<wchar_t>, operator_hijacker_allocator<wchar_t> > ss0(
          L" 123 456");
      std::basic_ostringstream<wchar_t, std::char_traits<wchar_t>, operator_hijacker_allocator<wchar_t> > ss(
          std::move(ss0));
      assert(ss.rdbuf() != nullptr);
      assert(ss.good());
      assert(ss.str() == L" 123 456");
      int i = 234;
      ss << i << ' ' << 567;
      assert(ss.str() == L"234 5676");
    }
#endif

  return 0;
}
