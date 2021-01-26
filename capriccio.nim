import asyncdispatch
import jester
import os
import strutils
import json
import re

routes:

  get re"(.+)":
    let source = request.matches[0].strip(chars={'/'})

    if "." in source:
      try:
        resp readFile("public" / source)
      except:
        resp "404!"
    else:

      let path = "files" / source / "/index.html"
      echo path
      
      if fileExists(path):
        resp readFile("template.html").replace("#CONTENT#", readFile(path))
      else:
        resp readFile("template.html").replace("#CONTENT#", "<div id=\"editable\"></div>")

  post "/api/login":
    let pass = request.body
    try:
      let comp = readFile("pass.txt").strip(chars={'\n', ' '})
      if pass == comp:
        resp %*{"success": true, "new": false}
      else:
        resp %*{"success": false, "new": false}
    except:
      writeFile("pass.txt", pass)
      resp %*{"success": true, "new": true}
  
  post "/api/edit":
    let data = parseJson(request.body)

    var path = "files" / data["loc"].getStr() / "index.html"

    let comp = readFile("pass.txt").strip(chars={'\n', ' '})
    if data["pass"].getStr() == comp:

      var past = "files"
      for i in path.split("/"):
        if i notin ["files", "index.html"]:
          past = past / i
          discard existsOrCreateDir(past)
      
      writeFile(past / "index.html", "<div id=\"editable\">" & data["body"].getStr() & "</div>")

      resp %*{"success": true}
    else:
      echo "Login failed!"
      resp %*{"success": false}
  
  post "/api/delete":
    let data = parseJson(request.body)
    let loc = data["loc"].getStr()

    let comp = readFile("pass.txt").strip(chars={'\n', ' '})
    if data["pass"].getStr() == comp:
      removeFile("files" / loc / "index.html")
      
      var removeAll = true
      for i in walkDir("files" / loc):
        removeAll = false
      
      if removeAll and ("files" / loc) notin ["files", "files/"]:
        removeDir("files" / loc)
      
      resp %*{"success": true}
    else:
      resp %*{"success": false}