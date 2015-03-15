local dictionary = require "dictionary"
local languages = require "language"
local parse = require "parse"
local text = require "text"

local orig = "[yells] Goodbye, [pauses] cruel multiverse! / plz DM kill me"
local strings = { "[yells]", " ", "Goodbye", ", ", "[pauses]", " ", "cruel", " ", "multiverse", "! ", "/ plz DM kill me" }

describe("parse", function()
  it("can break down text into strings of words and non-words", function()
    assert.are.same(strings, parse.to_strings(orig))
  end)
  describe("complexity", function()
    it("only works on words", function()
      assert.are.equal(nil, parse.skill_required(""))
      assert.are.equal(nil, parse.skill_required(5))
    end)
    it("is a function of word length", function()
      assert.are.equal(5, parse.skill_required("a"))
      assert.are.equal(25, parse.skill_required("babel"))
      assert.are.equal(100, parse.skill_required("pneumonoultramicroscopicsilicovolcanoconiosis"))
    end)
  end)
  it("can be translated when skill >= skill_required", function()
    assert.are.equal(false, parse.can_translate("",5))
    assert.are.equal(true, parse.can_translate("a",5))
    assert.are.equal(false, parse.can_translate("to",5))
  end)
  it("can be detected", function()
    assert.are.equal(false, parse.is_word(""))
    assert.are.equal(true, parse.is_word("test"))
    assert.are.equal(false, parse.is_word("1234"))
    assert.are.equal(false, parse.is_word("1234!"))
    assert.are.equal(false, parse.is_word("..."))
  end)
end)

local english_to_french
local blank_dict
describe("dictionaries", function()
  it("should be creatable", function()
    blank_dict = dictionary.new({})
    english_to_french = dictionary.new({
      good = "bon",
      goodbye = "au revoir",
      bye = "au revoir",
      cruel = "sadique",
      multi = "beaucoup"
    })
  end)
  it("should find words which exist", function()
    assert.are.equal("bon", english_to_french:lookup("good"))
    assert.are.equal("au revoir", english_to_french:lookup("BYE"))
    assert.are.equal("beaucoup", english_to_french:lookup("Multi"))
  end)
  it("should not find words which don't exit", function()
    assert.are.equal(nil, english_to_french:lookup("x"))
    assert.are.equal(nil, english_to_french:lookup("xy"))
    assert.are.equal(nil, english_to_french:lookup("abcdefghij"))
  end)
  it("should not find words of unique sizes", function()
    assert.are.equal(nil, english_to_french:lookup("to"))
    assert.are.equal(nil, english_to_french:lookup("a"))
    assert.are.equal(nil, english_to_french:lookup("seventeen"))
  end)
  it("should return the length of their longest word", function()
    assert.are.equal(7, english_to_french.longest)
  end)
  it("should return the length of their shortest word", function()
    assert.are.equal(3, english_to_french.shortest)
  end)
  it("should try to match partial words", function()
    local match, len = english_to_french:lookup_partial("multiverse")
    assert.are.equal("beaucoup", match)
    assert.are.equal(5, len)

    match, len = english_to_french:lookup_partial("bon")
    assert.are.equal(nil, match)
    assert.are.equal(0, len)
  end)
end)

local blank
local eng
local french
local asterisk
describe("languages", function()
  it("be creatable", function()
    asterisk = languages.new({ name = "asterisk" })
    blank = languages.new({ name = "blank", dictionary = blank_dict })
    eng = languages.new({ name = "eng" })
    french = languages.new({ name = "french", dictionary = english_to_french })
  end)
  it("default to asterisk obfuscation", function()
    assert.are.equal("*****", asterisk.obfuscate("fnord"))
  end)
  it("should create default abbreviations", function()
    assert.are.equal("blan",blank.abbrev)
    assert.are.equal("eng",eng.abbrev)
  end)
  it("use the first added language as the default", function()
    assert.are.equal(asterisk, languages.default)
  end)
  it("should translate whole words", function()
    assert.are.equal("bon", french:translate("good"))
    assert.are.equal("Au revoir", french:translate("Goodbye"))
    assert.are.equal("au revoir", french:translate("bye"))
    assert.are.equal("SADIQUE", french:translate("CRUEL"))
    assert.are.equal("Beaucoup", french:translate("MULti"))
  end)
  it("should translate partial words", function()
    assert.are.equal("beaucoupverse", french:translate("multiverse"))
    assert.are.equal("versebeaucoup", french:translate("versemulti"))
    assert.are.equal("verseBeaucoup", french:translate("verseMulti"))
    assert.are.equal("verseBEAUCOUP", french:translate("verseMULTI"))
  end)
  it("should match cases", function()
    assert.are.equal("Bon", languages.match_case("Good","bon"))
    assert.are.equal("B", languages.match_case("A","b"))
    assert.are.equal("BONJOUR", languages.match_case("HELLO","bonjour"))
    assert.are.equal("bonjour", languages.match_case("hELLO","bonjour"))
  end)
  it("use default with blank dictionaries", function()
    assert.are.equal("**********", blank:translate("multiverse"))
  end)
  describe("should", function()  
    local speech_problems_0 = asterisk:speak(orig, 0)
    local speech_problems_30 = asterisk:speak(orig, 30)
    local speech_problems_40 = asterisk:speak(orig, 40)
    local speech_100 = asterisk:speak(orig, 100)

    local writing_problems_0 = asterisk:write(orig, 0)
    local writing_problems_30 = asterisk:write(orig, 30)
    local writing_80 = asterisk:write(orig, 80)

    describe("flag words which cannot be", function()
      it("spoken", function()
        assert.are.same({"Goodbye","cruel","multiverse"}, speech_problems_0)
        assert.are.same({"Goodbye","multiverse"}, speech_problems_30)
        assert.are.same(orig, speech_100:translate(100))
      end)
      it("writen", function()
        assert.are.same({"Goodbye","cruel","multiverse"}, writing_problems_0)
        assert.are.same({"Goodbye","multiverse"}, writing_problems_30)
        assert.are.equal(80, writing_80.skill)
      end)
    end)
  end)
end)

describe("text", function()  
  local obf = "[yells] *******, [pauses] ***** **********! / plz DM kill me"
  local gcm = asterisk:write(orig, 80)
  it("should compute skill ranges", function()
    assert.are.equal(25, gcm.min_skill())
    assert.are.equal(50, gcm.max_skill())
  end)
  it("should obfuscate", function()
    assert.are.equal(obf, gcm.obfuscated())
  end)
  it("should completely translate", function()
    assert.are.equal(orig, gcm:translate(gcm.max_skill()))
  end)
  it("should not translate", function()
    assert.are.equal(obf, gcm:translate(gcm.min_skill() - 1))
  end)
  it("should partially translate", function()
    assert.are.equal("[yells] *******, [pauses] cruel **********! / plz DM kill me", gcm:translate(30))
  end)
  it("can have its language identified", function()
    assert.are.equal(nil, gcm.id_language(5))
    assert.are.equal(asterisk, gcm.id_language(12.5))
    assert.are.equal(asterisk, gcm.id_language(100))
  end)
end)