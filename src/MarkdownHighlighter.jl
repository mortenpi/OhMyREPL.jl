
using Crayons
using Tokenize
import Markdown

import .OhMyREPL.Passes.SyntaxHighlighter.SYNTAX_HIGHLIGHTER_SETTINGS
import .OhMyREPL.HIGHLIGHT_MARKDOWN

function Markdown.term(io::IO, md::Markdown.Code, columns)
    code = md.code
    # Want to remove potential.
    lang = md.language == "" ? "" : first(split(md.language))
    outputs = String[]
    sourcecodes = String[]
    do_syntax = false
    # e.g. md.language = "jldoctest; filter = r\"[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}\""
    if occursin(r"jldoctest;?", "jldoctest") || lang == "julia-repl"
        do_syntax = true
        code_blocks = split("\n" * code, "\njulia> ")
        for codeblock in code_blocks[2:end] #
            expr, pos = Meta.parse(codeblock, 1, raise = false);
            sourcecode, output = if pos > length(codeblock)
                codeblock, ""
            else
                ind = Base.nextind(codeblock, 0, pos)
                codeblock[1:ind-1], codeblock[ind:end]
            end
            push!(sourcecodes, string(sourcecode))
            push!(outputs, string(output))
        end
    elseif lang == "julia" || lang == ""
        do_syntax = true
        push!(sourcecodes, code)
        push!(outputs, "")
    end

    if do_syntax && HIGHLIGHT_MARKDOWN[]
        for (sourcecode, output) in zip(sourcecodes, outputs)
            tokens = collect(tokenize(sourcecode))
            crayons = fill(Crayon(), length(tokens))
            SYNTAX_HIGHLIGHTER_SETTINGS(crayons, tokens, 0)
            buff = IOBuffer()
            if lang == "jldoctest" || lang == "julia-repl"
                print(buff, Crayon(foreground = :red, bold = true), "julia> ", Crayon(reset = true))
            end
            for (token, crayon) in zip(tokens, crayons)
                print(buff, crayon)
                print(buff, untokenize(token))
                print(buff, Crayon(reset = true))
            end
            print(buff, output)

            str = String(take!(buff))
            for line in Markdown.lines(str)
                print(io, " "^Markdown.margin)
                println(io, line)
            end
        end
    else
        Base.with_output_color(:cyan, io) do io
            for line in Markdown.lines(md.code)
                print(io, " "^Markdown.margin)
                println(io, line)
            end
        end
    end
end
