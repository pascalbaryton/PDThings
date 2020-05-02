'
' a script to import [NClass][1] .erd files as PowerDesigner models
' it started as an answer to [a StackOverflow question][2],
'
' To be run with Tools > Execute Commands > Edit/Run Script inside PowerDesigner
'
' [1]: https://github.com/gbaychev/NClass
'      http://nclass.sourceforge.net/
' [2]: https://stackoverflow.com/questions/61523452/erd-files-from-common-data-model-how-to-open-erwin-powerdesigner
'

' force variable declaration
option explicit

dim fn : fn = GetFile

if fn <> "" then
   dim loaded : loaded = ImportFile(fn)
   if loaded then
      ' try some diagram cleanup
      dim diagram : set diagram = ActiveModel.defaultdiagram
      diagram.autolayout
   end if
end if

function ImportFile(fileName)
   ImportFile = false
   
   ' load ERD file as XML document
   dim doc : set doc = CreateObject("MSXML2.DOMDocument")
   doc.load(fileName)

   ' retrieve information from project
   dim p : set p = doc.getElementsByTagName("ProjectItem")
   if p.length = 0 then exit function
   set p = p.item(0)
   ' check diagram type
   dim ptype : ptype = p.attributes.getNamedItem("type").nodeValue
   if ptype <> "NClass.DiagramEditor.ClassDiagram.Diagram" and ptype <> "NClass.DiagramEditor.ClassDiagram.ClassDiagram" then exit function
   
   dim mn : mn = GetTextElement(p, "Name")
   dim lang : lang = GetTextElement(p, "Language")
   if lang = "CSharp" then
      lang = "C# 2.0"
   elseif lang = "Java" then
      lang = "Java"
   else
      lang = "Analysis"
   end if

   ' create model
   dim model : set model = CreateModel(PdOOM.Cls_Model, "|Language="+lang+"|Diagram=ClassDiagram")
   dim diagram : set diagram = model.DefaultDiagram
   if mn <> "" then model.SetNameAndCode mn,mn

   ' start entities enumeration
   dim entities : set entities = doc.getElementsByTagName("Entity")
   dim e, count
   count = -1
   dim mapent : set mapent = CreateObject("Scripting.Dictionary")
   dim mapsymb : set mapsymb = CreateObject("Scripting.Dictionary")
   ' nclass count y down; x,y starting at 0
   dim maxx, maxy
   maxx = 0
   maxy = 0
   for each e in entities
      count = count+1
      dim name : name = "Class_" + cstr(count)
      dim en : en = GetTextElement(e, "Name")
      if en <> "" then name = en
      dim loc : set loc = e.getElementsByTagName("Location")
      dim x,y
      if loc.length > 0 then
         set loc = loc.item(0)
         x = loc.attributes.getNamedItem("left").nodeValue
         y = loc.attributes.getNamedItem("top").nodeValue
         if x > maxx then maxx = x
         if y > maxy then maxy = y
      else
         output "*** unable to get position for entity " & name
         x = 0
         y = 0
      end if
      dim c : set c = model.classes.CreateNew
      ' keep track of entity by number, to draw relationships
      mapent.add cstr(count),c
      c.setNameAndCode name,name
      dim sym : set sym = diagram.AttachObject(c)
      mapsymb.add cstr(count),sym
      dim pos : set pos = sym.position
      pos.x = x
      pos.y = y
      ' add attributes
      dim atts : set atts = e.getElementsByTagName("Member")
      dim m
      for each m in atts
         if m.attributes.getNamedItem("type").nodeValue = "Field" then
            dim str : str = m.firstChild.nodeValue
            dim parts : parts = split(str,": ")
            dim att : set att = c.attributes.CreateNew
            att.setNameAndCode parts(0),parts(0)
            att.datatype = parts(1)
         end if
      next
   next
   
   ' update symbols position
   ' invert Y axis; center diagram; apply scale
   if maxx > 0 and maxy > 0 then
      dim ofsx : ofsx = maxx / 2
      dim ofsy : ofsy = maxy / 2
      dim ai : ai = mapsymb.items
      dim i
      for i=0 to mapsymb.count-1
         dim s : set s = ai(i)
         dim newpos : set newpos = s.position
         newpos.x = (newpos.x - ofsx) * 48
         newpos.y = -(newpos.y - ofsy) * 48
      next
   end if

   ' create relatonships
   dim rels : set rels = doc.getElementsByTagName("Relationship")
   dim r
   for each r in rels
      dim atype : atype = r.attributes.getNamedItem("type").nodeValue
      if atype = "Association" then
         dim first,second
         first = cstr(r.attributes.getNamedItem("first").nodeValue)
         second = cstr(r.attributes.getNamedItem("second").nodeValue)
         dim k : k = GetTextElement(r,"AssociationType")
         if mapent.exists(first) and mapent.exists(second) then
            dim cf,cs
            set cf = mapent.item(first)
            set cs = mapent.item(second)
            dim a : set a = model.associations.createnew
            set a.object1 = cf
            set a.object2 = cs
            if k = "Composition" then
               a.RoleAIndicator = "C"
            elseif k = "Aggregation" then
               a.RoleAIndicator = "A"
            end if
         end if
      end if
   next
   ' display associations
   diagram.completelinks

   ImportFile = true
end function

function GetTextElement(elt, name)
   GetTextElement = ""
   if elt is nothing then exit function
   dim n : set n = elt.getElementsByTagName(name)
   if n.length > 0 then
      GetTextElement = n.item(0).firstChild.nodeValue
   end if
end function

function GetFile()
   dim wsh : set wsh=CreateObject("WScript.Shell")
   dim oex : set oex=wsh.Exec("mshta.exe ""about:<input type=file id=FILE><script>FILE.click();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).WriteLine(FILE.value);close();resizeTo(0,0);</script>""")
   dim name : name = oex.StdOut.ReadLine
   GetFile = name
end function
