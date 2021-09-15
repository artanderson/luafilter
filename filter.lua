-- Declare variables
local title = {}
local path
local binder = "https://mybinder.org/v2/gh/aerospike-examples/interactive-notebooks/main?filepath="
local fname = PANDOC_STATE.input_files[1]

--Split string at delimiter
function Split(s, delimiter)
  local result = {}
  for match in string.gmatch(s, "([^"..delimiter.."]+)") do
    table.insert(result, match)
  end
  return result
end    

--get level 1 header info and populate title table
function Header(el)    
  content_str = pandoc.utils.stringify(el.content)
  if el.level == 1 then
    table.insert(title, content_str)
  end
  --Returns headers with original content. Fixes problem with printing headers twice.
    return pandoc.Header(el.level, el.content)
end 

--Format document yaml metadata block
function Meta(m)       
  local id = Split(fname, ".")
  --get language from jupyter metadata
  local lang = m.jupyter.kernelspec.language
  path = binder .. lang .. '/' .. fname    
  m.id = id[1]   
  m.title = title[1]
  --remove jupyter metadata
  m.jupyter = nil    
  return m   
end

--Removes TOC, converts code output to BlockQuote and removes extra div tags  
function Div (elem)
  local output = {}    
  --Remove TOC
  if elem.attributes['toc'] == 'true' then
    elem.content = {}   
  --Convert output to BlockQuote
  --Match div class to "output" and ensure content is a CodeBLock        
  elseif elem.classes[1]:match('output') and elem.content[1].t == 'CodeBlock' then
    --Split CodeBlock into a table of strings to preserve line breaks
    local code = Split(elem.content[1].text, "\n")
    for i, str in ipairs(code) do
        table.insert(output, pandoc.Str(str))
    end
    --Create LineBLock to feed into BlockQuote    
    elem.content = pandoc.BlockQuote(pandoc.LineBlock(output))   
  end  
  return elem.content     
end   

--[[ Still working on this stuff

function Plain (elem)
  local grab = false
  local arr = {}    
  for i, item in ipairs(elem.content) do    
    if item.t == 'RawInline' and item.text == '</pre>' then
      grab = false
    end
    if grab then
      table.insert(arr, item)        
    end
    if item.t == 'RawInline' and item.text == '<pre>' then
      grab = true       
    end    
  end
  local code = pandoc.utils.stringify(arr)
  local el = pandoc.utils.stringify(elem.content)    
  if code ~= '' then
        print(code)    
  end        
end    

Replaces inline <pre> tags with inline code
function RawInline (raw)
  if raw.format == 'html' and raw.text == '<pre>' or raw.text == '</pre>' then
    return pandoc.RawInline('markdown', '\n```\n')
  end
end

--Replaces block <pre> tags with code blocks
function RawBlock (raw)
  if raw.format == 'html' then
    return pandoc.CodeBlock(raw.text)
  end
end  ]]--