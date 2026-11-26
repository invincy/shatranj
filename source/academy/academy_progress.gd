extends RefCounted
var path:="user://academy-progress.cfg"
var completed:Dictionary={}
var save_failed:=false
func load_progress():
 completed.clear()
 var config=ConfigFile.new()
 if config.load(path)!=OK:return
 var values=config.get_value("academy","completed",[])
 if not values is Array:return
 for value in values:
  if (value is int or value is float) and int(value)==value and value>=0 and value<9:completed[int(value)]=true
func finish(index:int):
 if index<0 or index>=9:return
 completed[index]=true
 var config=ConfigFile.new();config.set_value("academy","completed",completed.keys());save_failed=config.save(path)!=OK
func next_lesson()->int:
 for index in range(9):
  if not completed.has(index):return index
 return 0
func xp()->int:return completed.size()*25
func count(indices:Array)->int:
 var result:=0
 for index in indices:
  if completed.has(index):result+=1
 return result
