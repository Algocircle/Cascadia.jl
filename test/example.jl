
#Example for using Cascadia to scrape webpages
#Display votes and urls for stackoverflow questions tagged with julia
using Cascadia
using Gumbo
using Requests

r = get("http://stackoverflow.com/questions/tagged/julia-lang")
h = parsehtml(convert(String, r.data))

qs = matchall(Selector(".question-summary"),h.root)

println("StackOverflow Julia Questions (votes  answered?  url)")

for q in qs
    votes = nodeText(matchall(Selector(".votes .vote-count-post "), q)[1])
    answered = length(matchall(Selector(".status.answered"), q)) > 0
    href = matchall(Selector(".question-hyperlink"), q)[1].attributes["href"]
    println("$votes  $answered  http://stackoverflow.com$href")
end
