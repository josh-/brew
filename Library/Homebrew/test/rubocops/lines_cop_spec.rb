require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/lines_cop"

describe RuboCop::Cop::FormulaAudit::Lines do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "correctable deprecated dependencies usage" do
      formulae = [{
        "dependency" => :automake,
        "correct"    => "automake",
      }, {
        "dependency" => :autoconf,
        "correct"    => "autoconf",
      }, {
        "dependency" => :libtool,
        "correct"    => "libtool",
      }, {
        "dependency" => :apr,
        "correct"    => "apr-util",
      }, {
        "dependency" => :tex,
      }]

      formulae.each do |formula|
        source = <<~EOS
          class Foo < Formula
            url 'http://example.com/foo-1.0.tgz'
            depends_on :#{formula["dependency"]}
          end
        EOS
        if formula.key?("correct")
          offense = ":#{formula["dependency"]} is deprecated. Usage should be \"#{formula["correct"]}\""
        else
          offense = ":#{formula["dependency"]} is deprecated"
        end
        expected_offenses = [{ message: offense,
                               severity: :convention,
                               line: 3,
                               column: 2,
                               source: source }]

        inspect_source(source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end
  end
end

describe RuboCop::Cop::FormulaAudit::ClassInheritance do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "inconsistent space in class inheritance" do
      source = <<~EOS
        class Foo<Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{ message: "Use a space in class inheritance: class Foo < Formula",
                             severity: :convention,
                             line: 1,
                             column: 10,
                             source: source }]

      inspect_source(source, "/homebrew-core/Formula/foo.rb")

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

describe RuboCop::Cop::FormulaAudit::Comments do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "commented cmake call" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          # system "cmake", ".", *std_cmake_args
        end
      EOS

      expected_offenses = [{ message: "Please remove default template comments",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "default template comments" do
      source = <<~EOS
        class Foo < Formula
          # PLEASE REMOVE
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{ message: "Please remove default template comments",
                             severity: :convention,
                             line: 2,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "commented out depends_on" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          # depends_on "foo"
        end
      EOS

      expected_offenses = [{ message: 'Commented-out dependency "foo"',
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

describe RuboCop::Cop::FormulaAudit::AssertStatements do
  subject(:cop) { described_class.new }

  it "assert ...include usage" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        assert File.read("inbox").include?("Sample message 1")
      end
    EOS

    expected_offenses = [{ message: "Use `assert_match` instead of `assert ...include?`",
                           severity: :convention,
                           line: 4,
                           column: 9,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "assert ...exist? without a negation" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        assert File.exist? "default.ini"
      end
    EOS

    expected_offenses = [{ message: 'Use `assert_predicate <path_to_file>, :exist?` instead of `assert File.exist? "default.ini"`',
                           severity: :convention,
                           line: 4,
                           column: 9,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "assert ...exist? with a negation" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        assert !File.exist?("default.ini")
      end
    EOS

    expected_offenses = [{ message: 'Use `refute_predicate <path_to_file>, :exist?` instead of `assert !File.exist?("default.ini")`',
                           severity: :convention,
                           line: 4,
                           column: 9,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "assert ...executable? without a negation" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        assert File.executable? f
      end
    EOS

    expected_offenses = [{ message: "Use `assert_predicate <path_to_file>, :executable?` instead of `assert File.executable? f`",
                           severity: :convention,
                           line: 4,
                           column: 9,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end
end

describe RuboCop::Cop::FormulaAudit::OptionDeclarations do
  subject(:cop) { described_class.new }

  it "unless build.without? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return unless build.without? "bar"
        end
      end
    EOS

    expected_offenses = [{ message: 'Use if build.with? "bar" instead of unless build.without? "bar"',
                           severity: :convention,
                           line: 5,
                           column: 18,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "unless build.with? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return unless build.with? "bar"
        end
      end
    EOS

    expected_offenses = [{ message: 'Use if build.without? "bar" instead of unless build.with? "bar"',
                           severity: :convention,
                           line: 5,
                           column: 18,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "negated build.with? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return if !build.with? "bar"
        end
      end
    EOS

    expected_offenses = [{ message: "Don't negate 'build.with?': use 'build.without?'",
                           severity: :convention,
                           line: 5,
                           column: 14,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "negated build.without? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return if !build.without? "bar"
        end
      end
    EOS

    expected_offenses = [{ message: "Don't negate 'build.without?': use 'build.with?'",
                           severity: :convention,
                           line: 5,
                           column: 14,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "unnecessary build.without? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return if build.without? "--without-bar"
        end
      end
    EOS

    expected_offenses = [{ message: "Don't duplicate 'without': Use `build.without? \"bar\"` to check for \"--without-bar\"",
                           severity: :convention,
                           line: 5,
                           column: 30,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "unnecessary build.with? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return if build.with? "--with-bar"
        end
      end
    EOS

    expected_offenses = [{ message: "Don't duplicate 'with': Use `build.with? \"bar\"` to check for \"--with-bar\"",
                           severity: :convention,
                           line: 5,
                           column: 27,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "build.include? conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return if build.include? "without-bar"
        end
      end
    EOS

    expected_offenses = [{ message: "Use build.without? \"bar\" instead of build.include? 'without-bar'",
                           severity: :convention,
                           line: 5,
                           column: 30,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "build.include? with dashed args conditional" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'
        def post_install
          return if build.include? "--bar"
        end
      end
    EOS

    expected_offenses = [{ message: "Reference 'bar' without dashes",
                           severity: :convention,
                           line: 5,
                           column: 30,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end

  it "def options usage" do
    source = <<~EOS
      class Foo < Formula
        desc "foo"
        url 'http://example.com/foo-1.0.tgz'

        def options
          [["--bar", "desc"]]
        end
      end
    EOS

    expected_offenses = [{ message: "Use new-style option definitions",
                           severity: :convention,
                           line: 5,
                           column: 2,
                           source: source }]

    inspect_source(source)

    expected_offenses.zip(cop.offenses).each do |expected, actual|
      expect_offense(expected, actual)
    end
  end
end

describe RuboCop::Cop::FormulaAudit::Miscellaneous do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "FileUtils usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          FileUtils.mv "hello"
        end
      EOS

      expected_offenses = [{ message: "Don't need 'FileUtils.' before mv",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "long inreplace block vars" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          inreplace "foo" do |longvar|
            somerandomCall(longvar)
          end
        end
      EOS

      expected_offenses = [{ message: "\"inreplace <filenames> do |s|\" is preferred over \"|longvar|\".",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "an invalid rebuild statement" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            rebuild 0
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
        end
      EOS

      expected_offenses = [{ message: "'rebuild 0' should be removed",
                             severity: :convention,
                             line: 5,
                             column: 4,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "OS.linux? check" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            if OS.linux?
              nil
            end
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
        end
      EOS

      expected_offenses = [{ message: "Don't use OS.linux?; Homebrew/core only supports macOS",
                             severity: :convention,
                             line: 5,
                             column: 7,
                             source: source }]

      inspect_source(source, "/homebrew-core/")

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "fails_with :llvm block" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
          fails_with :llvm do
            build 2335
            cause "foo"
          end
        end
      EOS

      expected_offenses = [{ message: "'fails_with :llvm' is now a no-op so should be removed",
                             severity: :convention,
                             line: 7,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "def test's deprecated usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'

          def test
            assert_equals "1", "1"
          end
        end
      EOS

      expected_offenses = [{ message: "Use new-style test definitions (test do)",
                             severity: :convention,
                             line: 5,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "deprecated skip_clean call" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          skip_clean :all
        end
      EOS

      expected_offenses = [{ message: <<~EOS.chomp,
        `skip_clean :all` is deprecated; brew no longer strips symbols
                Pass explicit paths to prevent Homebrew from removing empty folders.
                             EOS
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "build.universal? deprecated usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build.universal?
             "foo"
          end
        end
      EOS

      expected_offenses = [{ message: "macOS has been 64-bit only since 10.6 so build.universal? is deprecated.",
                             severity: :convention,
                             line: 4,
                             column: 5,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "build.universal? deprecation exempted formula" do
      source = <<~EOS
        class Wine < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build.universal?
             "foo"
          end
        end
      EOS

      inspect_source(source, "/homebrew-core/Formula/wine.rb")
      expect(cop.offenses).to be_empty
    end

    it "deprecated ENV.universal_binary usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build?
             ENV.universal_binary
          end
        end
      EOS

      expected_offenses = [{ message: "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated.",
                             severity: :convention,
                             line: 5,
                             column: 5,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "ENV.universal_binary deprecation exempted formula" do
      source = <<~EOS
        class Wine < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build?
            ENV.universal_binary
          end
        end
      EOS

      inspect_source(source, "/homebrew-core/Formula/wine.rb")
      expect(cop.offenses).to be_empty
    end

    it "deprecated ENV.x11 usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build?
             ENV.x11
          end
        end
      EOS

      expected_offenses = [{ message: 'Use "depends_on :x11" instead of "ENV.x11"',
                             severity: :convention,
                             line: 5,
                             column: 5,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "install_name_tool usage instead of ruby-macho" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "install_name_tool", "-id"
        end
      EOS

      expected_offenses = [{ message: 'Use ruby-macho instead of calling "install_name_tool"',
                             severity: :convention,
                             line: 4,
                             column: 10,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "ruby-macho alternatives audit exempted formula" do
      source = <<~EOS
        class Cctools < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "install_name_tool", "-id"
        end
      EOS

      inspect_source(source, "/homebrew-core/Formula/cctools.rb")
      expect(cop.offenses).to be_empty
    end

    it "npm install without language::Node args" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "npm", "install"
        end
      EOS

      expected_offenses = [{ message: "Use Language::Node for npm install args",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "npm install without language::Node args in kibana(exempted formula)" do
      source = <<~EOS
        class KibanaAT44 < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "npm", "install"
        end
      EOS

      inspect_source(source, "/homebrew-core/Formula/kibana@4.4.rb")
      expect(cop.offenses).to be_empty
    end

    it "depends_on with an instance as argument" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on FOO::BAR.new
        end
      EOS

      expected_offenses = [{ message: "`depends_on` can take requirement classes instead of instances",
                             severity: :convention,
                             line: 4,
                             column: 13,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "old style OS check" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on :foo if MacOS.snow_leopard?
        end
      EOS

      expected_offenses = [{ message: "\"MacOS.snow_leopard?\" is deprecated, use a comparison to MacOS.version instead",
                             severity: :convention,
                             line: 4,
                             column: 21,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "non glob DIR usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          rm_rf Dir["src/{llvm,test,librustdoc,etc/snapshot.pyc}"]
          rm_rf Dir["src/snapshot.pyc"]
        end
      EOS

      expected_offenses = [{ message: 'Dir(["src/snapshot.pyc"]) is unnecessary; just use "src/snapshot.pyc"',
                             severity: :convention,
                             line: 5,
                             column: 13,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "system call to fileUtils Method" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "mkdir", "foo"
        end
      EOS

      expected_offenses = [{ message: 'Use the `mkdir` Ruby method instead of `system "mkdir", "foo"`',
                             severity: :convention,
                             line: 4,
                             column: 10,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "top-level function def outside class body" do
      source = <<~EOS
        def test
           nil
        end
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{ message: "Define method test in the class body, not at the top-level",
                             severity: :convention,
                             line: 1,
                             column: 0,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "Using ARGV to check options" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            verbose = ARGV.verbose?
          end
        end
      EOS

      expected_offenses = [{ message: "Use build instead of ARGV to check options",
                             severity: :convention,
                             line: 5,
                             column: 14,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it 'man+"man8" usage' do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            man1.install man+"man8" => "faad.1"
          end
        end
      EOS

      expected_offenses = [{ message: '"man+"man8"" should be "man8"',
                             severity: :convention,
                             line: 5,
                             column: 22,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "hardcoded gcc compiler" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            system "/usr/bin/gcc", "foo"
          end
        end
      EOS

      expected_offenses = [{ message: "Use \"\#{ENV.cc}\" instead of hard-coding \"gcc\"",
                             severity: :convention,
                             line: 5,
                             column: 12,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "hardcoded g++ compiler" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            system "/usr/bin/g++", "-o", "foo", "foo.cc"
          end
        end
      EOS

      expected_offenses = [{ message: "Use \"\#{ENV.cxx}\" instead of hard-coding \"g++\"",
                             severity: :convention,
                             line: 5,
                             column: 12,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "hardcoded llvm-g++ compiler" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            ENV["COMPILER_PATH"] = "/usr/bin/llvm-g++"
          end
        end
      EOS

      expected_offenses = [{ message: "Use \"\#{ENV.cxx}\" instead of hard-coding \"llvm-g++\"",
                             severity: :convention,
                             line: 5,
                             column: 28,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "hardcoded gcc compiler" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            ENV["COMPILER_PATH"] = "/usr/bin/gcc"
          end
        end
      EOS

      expected_offenses = [{ message: "Use \"\#{ENV.cc}\" instead of hard-coding \"gcc\"",
                             severity: :convention,
                             line: 5,
                             column: 28,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "formula path shortcut : man" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            mv "\#{share}/man", share
          end
        end
      EOS

      expected_offenses = [{ message: '"#{share}/man" should be "#{man}"',
                             severity: :convention,
                             line: 5,
                             column: 17,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "formula path shortcut : libexec" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            mv "\#{prefix}/libexec", share
          end
        end
      EOS

      expected_offenses = [{ message: "\"\#\{prefix}/libexec\" should be \"\#{libexec}\"",
                             severity: :convention,
                             line: 5,
                             column: 18,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "formula path shortcut : info" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            system "./configure", "--INFODIR=\#{prefix}/share/info"
          end
        end
      EOS

      expected_offenses = [{ message: "\"\#\{prefix}/share/info\" should be \"\#{info}\"",
                             severity: :convention,
                             line: 5,
                             column: 47,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "formula path shortcut : man8" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def install
            system "./configure", "--MANDIR=\#{prefix}/share/man/man8"
          end
        end
      EOS

      expected_offenses = [{ message: "\"\#\{prefix}/share/man/man8\" should be \"\#{man8}\"",
                             severity: :convention,
                             line: 5,
                             column: 46,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "dependecies which have to vendored" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on "lpeg" => :lua51
        end
      EOS

      expected_offenses = [{ message: "lua modules should be vendored rather than use deprecated depends_on \"lpeg\" => :lua51`",
                             severity: :convention,
                             line: 4,
                             column: 24,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "manually setting env" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "export", "var=value"
        end
      EOS

      expected_offenses = [{ message: "Use ENV instead of invoking 'export' to modify the environment",
                             severity: :convention,
                             line: 4,
                             column: 10,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "dependencies with invalid options" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on "foo" => "with-bar"
        end
      EOS

      expected_offenses = [{ message: "Dependency foo should not use option with-bar",
                             severity: :convention,
                             line: 4,
                             column: 13,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "inspecting version manually" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if version == "HEAD"
            foo()
          end
        end
      EOS

      expected_offenses = [{ message: "Use 'build.head?' instead of inspecting 'version'",
                             severity: :convention,
                             line: 4,
                             column: 5,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "deprecated ENV.fortran usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          test do
            ENV.fortran
          end
        end
      EOS

      expected_offenses = [{ message: "Use `depends_on :fortran` instead of `ENV.fortran`",
                             severity: :convention,
                             line: 5,
                             column: 4,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "deprecated ARGV.include? (--HEAD) usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          test do
            head = ARGV.include? "--HEAD"
          end
        end
      EOS

      expected_offenses = [{ message: 'Use "if build.head?" instead',
                             severity: :convention,
                             line: 5,
                             column: 26,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "deprecated MACOS_VERSION const usage" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          test do
            version = MACOS_VERSION
          end
        end
      EOS

      expected_offenses = [{ message: "Use MacOS.version instead of MACOS_VERSION",
                             severity: :convention,
                             line: 5,
                             column: 14,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "deprecated if build.with? conditional dependency" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on "foo" if build.with? "with-foo"
        end
      EOS

      expected_offenses = [{ message: 'Replace depends_on "foo" if build.with? "with-foo" with depends_on "foo" => :optional',
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "unless conditional dependency with build.without?" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on :foo unless build.without? "foo"
        end
      EOS

      expected_offenses = [{ message: 'Replace depends_on :foo unless build.without? "foo" with depends_on :foo => :recommended',
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "unless conditional dependency with build.include?" do
      source = <<~EOS
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on :foo unless build.include? "without-foo"
        end
      EOS

      expected_offenses = [{ message: 'Replace depends_on :foo unless build.include? "without-foo" with depends_on :foo => :recommended',
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end
