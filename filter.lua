function Meta (m)
  m.title = "title"    
  return m
end    

function Div (elem)
  if elem.attributes['toc'] == 'true' then
    elem.content = {}   
  elseif elem.classes[1]:match('output') then
    elem.content = pandoc.BlockQuote(elem.content[1])   
  end  
  return elem.content     
end

function RawInline (raw)
  if raw.format == 'html' and raw.text == '<pre>' or raw.text == '</pre>' then
    return pandoc.RawInline('markdown', '\n```\n')
  end
end

function RawBlock (raw)
  if raw.format == 'html' then
    return pandoc.CodeBlock(raw.text)
  end
end
