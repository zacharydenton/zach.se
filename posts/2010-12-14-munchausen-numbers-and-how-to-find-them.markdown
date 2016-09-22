---
title: Munchausen Numbers and How to Find Them
excerpt: An introduction to Munchausen numbers and how to find them with various programming languages.
math: true
---

There are those who would have you believe that [every number is
interesting][]. However, there are interesting numbers and then there
are *interesting* numbers. Today I'm going to talk about numbers in the
latter category.

Munchausen numbers are numbers with the property that the sum of their
digits raised to themselves equals the number itself. I think this is
best explained with an example:

$$3^3 + 4^4 + 3^3 + 5^5 = 3435$$

I don't know about you, but I find this extremely interesting! (Come on!
You don't think that's interesting?) In any case, I decided to write a
few different programs to find these numbers.

The basic algorithm I came up with is as follows:

-   Separate the number into its constituent digits.
-   Find the sum of each digit raised to itself.
-   If this sum equals the original number, then it is a Munchausen
    number.

That's fairly self-explanatory, right? Let me show you a few different
ways to do this.

### Ruby

Ruby was the first "real" programming language I learned. Before Ruby, I
was writing simple programs on my TI-89, but that doesn't really count.
If you're wondering, I first learned how to program by reading the
excellent [*Learn to Program*][], by Chris Pine.

In Ruby, the easiest way to get the digits of a number is simply to
convert the number into a string. Once that is established, one simply
needs to apply the aforementioned algorithm to each number within a
certain limit to find the Munchausen numbers within that limit:

~~~~ {.ruby}
#!/usr/bin/env ruby
# munchausen.rb - finds munchausen numbers

5000.times do |i|
    digits = i.to_s()
    sum = 0
    digits.each_char do |digit|
        digit = digit.to_i()
        sum += digit ** digit
    end
    if sum == i
        puts i.to_s() + " (munchausen)"
    end
end
~~~~

### C

C is great if you need to eke out every last drop of performance from
your machine. I wouldn't think of using it in any other case, though.
That being said, it is much easier than assembly language, but come on
people -- this is the 21st century.

I took a slightly different approach here and used modular arithmetic to
extract the digits from the number. To find the least significant digit,
we take the remainder when the number is divided by 10. We do this until
all digits have been extracted. Then we simply apply the algorithm as in
the previous example.

~~~~ {.c}
// calculate munchausen numbers
#include <stdio.h>
#include <math.h>

int limit = 5000; // the upper bound of the search

int i;
int main() {
    for (i = 1; i < limit; i++) {
        // loop through each digit in i
        // e.g. for 1000 we get 0, 0, 0, 1.
        int number = i;
        int sum = 0;
        while (number > 0) {
            int digit = number % 10;
            number = number / 10;
            // find the sum of the digits 
            // raised to themselves 
            sum += pow(digit, digit);
        }
        if (sum == i) {
            // the sum is equal to the number
            // itself; thus it is a 
            // munchausen number
            printf("%i (munchausen)\n", i);
        } 
    }
    return 0;
}
~~~~

### Clojure

Clojure is an interesting new language, conceived in 2008. It is a Lisp
which targets the Java Virtual Machine, meaning it can make use of any
existing Java code whilst being written in a functional style.

Functional programming is an intriguing concept. It seems more
theoretical than the imperative style I am used to, but perhaps that is
because I am learning the language by reading [*Structure and
Interpretation of Computer Programs*][].

One thing about Clojure that seems strange to me is the fact that it
lacks a standard library. This means that you have to define your own
exponentiation function. In this case, I just used a function from the
Java standard library.

The other idiosyncrasy I noticed is that in Clojure, converting a char
to an int returns the ASCII representation of that char, rather than
performing a direct conversion. Thus, we must subtract 48 in order to
receive the number itself.

~~~~ {.clojure}
#!/usr/bin/env clojure
(defn ** [x n]
  (. (. java.math.BigInteger (valueOf x)) (pow n)))

(defn raise-to-itself [number]
  (** number number))

(defn digits [number]
  ; convert the number to a string,
  ; and convert each char to an int.
  ;
  ; subtract 48 because casting a char
  ; to an int returns the ASCII
  ; representation of that char.
  (map #(- (int %) 48) (str number))) 

(defn munchausen? [number]
  ; if the sum of the digits raised to
  ; themselves is equal to the number 
  ; itself, then it is a munchausen number.
  (= (apply + (map raise-to-itself (digits number))) number))

(def munchausen (filter munchausen? (range 5000)))
(println munchausen)
~~~~

### Python

Python is easily my favorite language. Everything about it just seems
"right". Of course, this is probably because it is the language I use
the most -- but then we have a chicken-or-egg scenario, don't we?

Here's the program written in Python. I used it to find every Munchausen
number less than 500,000,000. After thirty minutes or so of intense
computation, it turns out that the only Munchausen numbers are 1 and
3435. Others have posited that 438,579,088 is a Munchausen number, but
this is false because $0^0 = 1$, at least in most programming languages.

~~~~ {.python}
#!/usr/bin/env python3
# calculates munchausen numbers
#
# these are numbers with the property
# that the sum of its digits raised
# to themselves produces the original
# number.

for i in range(5000):
    digits = (int(digit) for digit in str(i))
    if sum(digit ** digit for digit in digits) == i:
        print(i, "(munchausen)")
~~~~

  [every number is interesting]: http://en.wikipedia.org/wiki/Interesting_number_paradox
  [*Learn to Program*]: http://pine.fm/LearnToProgram/
    "Learn to Program"
  [*Structure and Interpretation of Computer Programs*]: http://mitpress.mit.edu/sicp/full-text/book/book.html
    "Structure and Interpretation of Computer Programs"
