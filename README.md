#Test Launcher -->

Test Launcher takes some input and tries to figure out what test you want to run. It makes running tests on the command line much easier.  Test Launcher works with Minitest and probably TestUnit.  RSpec isn't supported.  If you use RSpec and you think this would be handy, let me know!

Let's suppose you want to run the test `test_name` in your `blog_post_test.rb`.  

Without Test Launcher, you might type this:

```
ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

But with Test Launcher, you can just type this:

```
t test_blog_name_thing

#=> ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

What if you want to run a whole file?  Just go for it!

```
t blog_post_test

#=> ruby -I test test/models/blog_post_test.rb
```

What if you just have the class name for the test?

```
t BlogPostTest

#=> ruby -I test test/models/blog_post_test.rb
```

But what if you aren't specific enough?

```
t test_blog_na

#=> Found 10 test methods in 3 files.
#=> Running most recently edited. Run with '--all' to run all the tests.
#=> ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

Super fun? OH YEAH!

#Installation

To install:

```
gem install test_launcher
```

#Setup

This gem installs one executable called `test_launcher`.  That executable must be called with the `find` method, like so:

```
test_launcher find test_name_to_find
```

For me, that's way too much to type, so I recommend adding an alias to your `.bash_profile` like so:

```
alias t='test_launcher find'
```

Now you can just type `t` instead of `test_launcher find`.  Much nicer!

#Usage

Test Launcher searches for tests based on your input.

Suppose you type `t thing`.  It will run tests using this priority preference:

1. A single, specific test method name or partial name
  - `def test_the_thing`

1. Multiple test method names in the same file
  - `def test_the_thing` and `def test_the_other_thing`

1. A single test file
  - matches on `thing_test.rb`

1. Any test file based on a generic search
  - runs `stuff_test.rb` because it found the word `thing` inside of it

Any time it matches multiple files, it will default to running the most recently edited file.  You can append `--all` if you want to run all matching tests.

#Does it work with inline gems?

Yes!

Test Launcher will automatically move to the correct subdirectory in order to run the tests.  For example, if `thing_test.rb` is within your inline_gem, you can run:


```
t thing_test

#=> cd ./path/to/inline_gem && ruby -I test test/thing_test.rb
```

You don't have to run Test Launcher from the root of your project either.  It will figure things out.

