extends Node2D

func generate_puzzle(width, height, colors = {"cell": Color("#35a989"), "line": Color("#354444"), "drawnLine": Color(1,1,1)}):
	var puzzle = {
		"points": [],
		"connections": [],
		"cells": [],
		"line width": 18,
		"colors": colors
	}
	for x in range(0, width + 1):
		for y in range(0, height + 1):
			if x == 0 and y == height:
				puzzle["points"].append([Vector2(600 * x / width, 600 * y / height), 1, 0, 0])
			elif x == width and y == 0:
				puzzle["points"].append([Vector2(600 * x / width, 600 * y / height), 0, 1.125, 0])
			else:
				puzzle["points"].append([Vector2(600 * x / width, 600 * y / height), 0, 0, 0])
			if y > 0:
				puzzle["connections"].append([[puzzle["points"].size() - 2, puzzle["points"].size() - 1],0,0])
			if x > 0:
				puzzle["connections"].append([[puzzle["points"].size() - height - 2, puzzle["points"].size() - 1],0,0])
			if x > 0 and y > 0:
				puzzle["cells"].append([[puzzle["points"].size() - height - 3, puzzle["points"].size() - height - 2, puzzle["points"].size() - 1, puzzle["points"].size() - 2],0])
	
	return puzzle

var currentPuzzle = {}

func draw_puzzle(puzzle, offset, solving = true, timeline = []):
	if solving:
		currentPuzzle = puzzle
		currentPuzzle["offset"] = offset
		currentPuzzle["startPoints"] = {}
		currentPuzzle["solving"] = {"witness": false, "soko": false, "taiji": false, "lockpick": false}
		currentPuzzle["timeline"] = timeline
		
	for i in puzzle["cells"]:
		var cell = Polygon2D.new()
		add_child(cell)
		var tempList = []
		for v in i[0]:
			tempList.append(offset + puzzle["points"][v][0])
		cell.polygon = PackedVector2Array(tempList)
		cell.color = puzzle["colors"]["cell"]
	
	for i in puzzle["connections"]:
		var line = Line2D.new()
		add_child(line)
		line.add_point(offset + puzzle["points"][i[0][0]][0])
		line.add_point(offset + puzzle["points"][i[0][1]][0])
		line.begin_cap_mode = 2
		line.end_cap_mode = 2
		line.default_color = puzzle["colors"]["line"]
		line.width = puzzle["line width"]
	
	for i in range(puzzle["points"].size()):
		if puzzle["points"][i][1] > 0:
			var startPoint = MeshInstance2D.new()
			add_child(startPoint)
			startPoint.global_translate(offset + puzzle["points"][i][0])
			startPoint.mesh = SphereMesh.new()
			startPoint.global_scale = Vector2(puzzle["line width"],puzzle["line width"]) * 2
			startPoint.self_modulate = puzzle["colors"]["line"]
			if solving:
				currentPuzzle["startPoints"][i] = startPoint
		if puzzle["points"][i][2] > 0:
			var endPoint = Line2D.new()
			add_child(endPoint)
			endPoint.add_point(offset + puzzle["points"][i][0])
			endPoint.add_point(offset + puzzle["points"][i][0] + Vector2(sin(TAU * puzzle["points"][i][2]),-cos(TAU * puzzle["points"][i][2])) * 18)
			endPoint.begin_cap_mode = 2
			endPoint.end_cap_mode = 2
			endPoint.default_color = puzzle["colors"]["line"]
			endPoint.width = puzzle["line width"]

func _input(event):
	
	if event is InputEventMouseButton and event.is_pressed() and event.as_text() == "Right Mouse Button" and currentPuzzle["solving"]["witness"]:
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		currentPuzzle["solving"]["witness"] = false
		for i in currentPuzzle["startPoints"]:
			currentPuzzle["startPoints"][i].self_modulate = currentPuzzle["colors"]["line"]
		for line in currentPuzzle["solving"]["lines"]:
			line.queue_free()
			currentPuzzle["solving"]["lines"].pop_back()
	
	if event is InputEventMouseButton and event.is_pressed() and event.as_text() == "Left Mouse Button" and not currentPuzzle["solving"]["witness"]:
		for i in currentPuzzle["startPoints"]:
			if sqrt((event.position.x - (currentPuzzle["offset"] + currentPuzzle["points"][i][0]).x) ** 2 + (event.position.y - (currentPuzzle["offset"] + currentPuzzle["points"][i][0]).y) ** 2) < 2 * currentPuzzle["line width"]:
				currentPuzzle["startPoints"][i].self_modulate = currentPuzzle["colors"]["drawnLine"]
				DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
				currentPuzzle["solving"]["witness"] = true
				currentPuzzle["solving"]["line_points"] = [[i]]
				currentPuzzle["solving"]["lines"] = [Line2D.new()]
				currentPuzzle["solving"]["on_point"] = true
				add_child(currentPuzzle["solving"]["lines"][0])
	
	if event is InputEventMouseMotion and currentPuzzle["solving"]["witness"]:
		for line in currentPuzzle["solving"]["lines"]:
			line.queue_free()
			currentPuzzle["solving"]["lines"].pop_back()
		
		var angle = event.relative.angle()
		
		if currentPuzzle["solving"]["on_point"]:
			var angles = []
			for i in currentPuzzle["connections"]:
				var index = i[0].find(currentPuzzle["solving"]["line_points"][-1][-1])
				if index != -1:
					angles.append([i[0][1-index], currentPuzzle["points"][i[0][1-index]][0].angle_to_point(currentPuzzle["points"][i[0][index]][0])])
			
			for i in angles:
				if not ((i[1] - PI < angle and angle < i[1] + PI) or (i[1] - PI < angle + TAU and angle + TAU < i[1] + PI)):
					angles.erase(i)
			
			var next_point = []
			for i in angles:
				if next_point.size() == 0:
					next_point = [i[0], angle_difference(i[1],angle)]
				elif angle_difference(i[1],angle) < next_point[1]:
					next_point = [i[0], angle_difference(i[1],angle)]
			
			next_point[1] = currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-1]][0].angle_to_point(currentPuzzle["points"][next_point[0]][0])
			
			print(next_point)
			
			if currentPuzzle["solving"]["line_points"][-1].size() == 1:
				currentPuzzle["solving"]["next_point"] = next_point
				
				currentPuzzle["solving"]["line_points"][-1].append([currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-1]][0],0])
				
				print(currentPuzzle["solving"]["line_points"])
			else:
				if next_point[0] == currentPuzzle["solving"]["line_points"][-1][-2]:
					currentPuzzle["solving"]["line_points"][-1][-1] = [currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-1]][0],currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-1]][0].distance_to(currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-2]][0])]
					print(currentPuzzle["solving"]["line_points"])
				else:
					currentPuzzle["solving"]["next_point"] = next_point
					
					currentPuzzle["solving"]["line_points"][-1].append([currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-1]][0],0])
					
					print(currentPuzzle["solving"]["line_points"])
			
			currentPuzzle["solving"]["on_point"] = false
		
		else:
			
			var distance = cos(angle - currentPuzzle["solving"]["next_point"][1]) * sqrt((event.relative[0]) ** 2 + event.relative[1] ** 2)
			
			distance += currentPuzzle["solving"]["line_points"][-1][-1][1]
			
			var pos = Vector2(cos(currentPuzzle["solving"]["next_point"][1]),sin(currentPuzzle["solving"]["next_point"][1])) * distance
			
			var start = currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-2]][0]
			
			var end = currentPuzzle["points"][currentPuzzle["solving"]["next_point"][0]][0]
			
			if (start < end and pos > end) or (start > end and pos < end):
				currentPuzzle["solving"]["line_points"][-1][-1] = currentPuzzle["solving"]["next_point"][0]
				currentPuzzle["solving"]["on_point"] = true
				print(currentPuzzle["solving"]["line_points"])
			elif (start < end and pos < start) or (start > end and pos > start):
				currentPuzzle["solving"]["line_points"][-1].pop_back()
				currentPuzzle["solving"]["on_point"] = true
				print(currentPuzzle["solving"]["line_points"])
			else:
				currentPuzzle["solving"]["line_points"][-1][-1] = [pos + currentPuzzle["points"][currentPuzzle["solving"]["line_points"][-1][-2]][0], distance]
		
		for i in currentPuzzle["solving"]["line_points"]:
			currentPuzzle["solving"]["lines"].append(Line2D.new())
			add_child(currentPuzzle["solving"]["lines"][-1])
			currentPuzzle["solving"]["lines"][-1].begin_cap_mode = 2
			currentPuzzle["solving"]["lines"][-1].end_cap_mode = 2
			currentPuzzle["solving"]["lines"][-1].joint_mode = 2
			currentPuzzle["solving"]["lines"][-1].default_color = currentPuzzle["colors"]["drawnLine"]
			currentPuzzle["solving"]["lines"][-1].width = currentPuzzle["line width"]
			for point in i:
				match typeof(point):
					TYPE_INT:
						currentPuzzle["solving"]["lines"][-1].add_point(currentPuzzle["offset"] + currentPuzzle["points"][point][0])
					TYPE_ARRAY:
						currentPuzzle["solving"]["lines"][-1].add_point(currentPuzzle["offset"] + point[0])
		
		

func _init():
	var puzzle = generate_puzzle(4,4)
	print(puzzle)
	draw_puzzle(puzzle,Vector2(276,24))
