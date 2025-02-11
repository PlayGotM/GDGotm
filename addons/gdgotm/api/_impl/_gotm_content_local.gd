class_name _GotmContentLocal

const UNDEFINED := {}


static func create(api: String, data: Dictionary) -> Dictionary:
	if data.key && !get_by_key_sync(data.key).is_empty():
		return {}
	var created = _GotmUtility.get_iso_from_unix_time()
	var score = {
		"path": _GotmUtility.create_resource_path(api),
		"author": _GotmAuthLocal.get_user(),
		"name": data.name,
		"key": data.key,
		"private": data.private,
		"data": "",
		"props": data.props,
		"parents": data.parents,
		"updated": created,
		"created": created
	}
	return _format(_LocalStore.create(score))


static func _decode_cursor(cursor: String) -> Array:
	var decoded := _GotmUtility.decode_cursor(cursor)
	var target: String = decoded[1]
	if !target.is_empty():
		decoded[1] = target.substr(0, target.length() - 1).replace("-", "/")
	return decoded


static func delete(id: String) -> bool:
	await delete_blob(id)
	_GotmMarkLocal.delete_by_target_sync(id)
	var result := _LocalStore.delete(id)
	var to_delete := []
	for child in _LocalStore.get_all("contents"):
		var parents: Array = child.get("parents")
		if parents.is_empty():
			continue
		if !parents.has(id):
			continue
		parents.erase(id)
		if parents.is_empty():
			to_delete.append(child)
	for child in to_delete:
		delete(child.path)
	return result


static func delete_blob(content_id: String) -> bool:
	var content := _LocalStore.fetch(content_id)
	if content.is_empty():
		return false
	return _GotmBlobLocal.delete_sync(content.data)


static func fetch(path: String) -> Dictionary:
	return _format(_LocalStore.fetch(path))


static func _format(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	data = _GotmUtility.copy(data, {})
	if !data.has("parents"):
		data.parents = []
	data.updated = _GotmUtility.get_unix_time_from_iso(data.updated)
	data.created = _GotmUtility.get_unix_time_from_iso(data.created)
	return data


static func _get_by_content_sort(params: Dictionary) -> Array:
	var matches := []
	params = params.duplicate()
	var sort = _GotmUtility.get_last_element(params.sorts) if params.get("sorts") else {"prop": "created", "descending": true}
	params.sorts = [sort]
	var is_private = null
	var filters: Array = params.filters if params.has("filters") else []
	for filter in filters:
		if filter.prop == "private":
			is_private = !!filter.get("value")
	if is_private == null:
		filters = filters.duplicate()
		filters.append({"prop": "private", "value": false})
		params.filters = filters
	for content in _LocalStore.get_all("contents"):
		if _match_content(content, params):
			matches.append(content)
	var descending = !!sort.get("descending")
	var predicate := ContentSearchPredicate.new()
	predicate.prop = sort.prop
	for m in matches:
		m.value = _get_content_value(sort.prop, m, UNDEFINED)
	matches.sort_custom(predicate.is_greater_than if descending else predicate.is_less_than)
	if params.get("after"):
		print_debug(params)
		var cursor := _decode_cursor(params.after)
		var cursor_content = {"value": cursor[0], "path": cursor[1]}
		var after_matches := []
		for i in range(0, matches.size()):
			var m = matches[i]
			m = {"value": m.value, "path": m.path}
			if cursor_content.path == m.path && cursor_content.value == m.value:
				continue
			if descending && predicate.is_greater_than(cursor_content, m) || !descending && predicate.is_less_than(cursor_content, m):
				after_matches.append(matches[i])
		matches = after_matches
	if params.get("limit"):
		while matches.size() > params.limit:
			matches.pop_back()

	for i in range(0, matches.size()):
		matches[i] = _format(matches[i])
	return matches


static func get_by_key_sync(key: String) -> Array:
	for content in _LocalStore.get_all("contents"):
		if content.key == key && !content.private:
			return [_format(content)]
	return []


static func _get_content_value(prop: String, content: Dictionary, undefined_value = null):
	match prop:
		"key", "name", "author", "data", "private", "updated", "created":
			return content[prop]

		"directory":
			var key: String = content.key
			var parts := key.split("/", false)
			if parts.is_empty():
				return ""
			parts.resize(parts.size() - 1)
			return "/".join(parts)

		"extension":
			var key: String = content.key
			var parts := key.split("/", false)
			if parts.is_empty():
				return ""
			var dot_split: Array = parts[parts.size() - 1].split(".", false)
			if dot_split.size() <= 1:
				return ""
			dot_split.remove_at(0)
			return ".".join(dot_split)

		"size":
			var blob := _LocalStore.fetch(content.data)
			return blob.size if !blob.is_empty() else 0

		"score":
			var score: int = 0
			for mark in _LocalStore.get_all("marks"):
				if mark.target == content.path:
					if mark.name == "upvote":
						score += 1
					elif mark.name == "downvote":
						score -= 1
			return score

	if prop.begins_with("props"):
		return _GotmUtility.get_nested_value(prop, content, undefined_value)
	return undefined_value


static func list(query: String, params: Dictionary = {}) -> Array:
	if query == "byKey":
		return get_by_key_sync(params.key)
	if query == "byContentSort":
		return _get_by_content_sort(params)
	return []


static func _match_content(content: Dictionary, params: Dictionary) -> bool:
	var sorts: Array = params.get("sorts") if params.has("sorts") else []
	var filters: Array = params.get("filters") if params.has("filters") else []

	for sort in sorts:
		var value = _get_content_value(sort.prop, content, UNDEFINED)
		if _GotmUtility.is_strictly_equal(value, UNDEFINED):
			return false

	for filter in filters:
		if filter.prop == "namePart":
			if !filter.has("value") || !_GotmUtility.is_partial_search_match(filter.value, content.name):
				return false
			continue

		if filter.prop == "parents":
			if !filter.has("value") || !(filter.value is Array):
				return false
			if filter.value:
				for parent in filter.value:
					if !content.parents.has(parent):
						return false
			elif content.parents:
				return false
			continue

		var value = _get_content_value(filter.prop, content, UNDEFINED)
		if _GotmUtility.is_strictly_equal(value, UNDEFINED):
			return false

		if filter.has("value"):
			if !_GotmUtility.is_fuzzy_equal(filter.value, value):
				return false
			continue

		if filter.has("min"):
			if filter.get("minExclusive"):
				if !_GotmUtility.is_greater(value, filter.get("min")):
					return false
			else:
				if _GotmUtility.is_less(value, filter.get("min")):
					return false

		if filter.has("max"):
			if filter.get("maxExclusive"):
				if !_GotmUtility.is_less(value, filter.get("max")):
					return false
			else:
				if _GotmUtility.is_greater(value, filter.get("max")):
					return false

	return true


static func update(id: String, data: Dictionary) -> Dictionary:
	return _format(_LocalStore.update(id, data))


class ContentSearchPredicate:
	var prop: String

	func is_greater_than(a, b) -> bool:
		var a_value = a.value
		var b_value = b.value
		if _GotmUtility.is_strictly_equal(a_value, UNDEFINED) || _GotmUtility.is_strictly_equal(b_value, UNDEFINED):
			return false
		return _GotmUtility.is_greater(a_value, b_value) || _GotmUtility.is_fuzzy_equal(a_value, b_value) && a.path > b.path

	func is_less_than(a, b) -> bool:
		var a_value = a.value
		var b_value = b.value
		if _GotmUtility.is_strictly_equal(a_value, UNDEFINED) || _GotmUtility.is_strictly_equal(b_value, UNDEFINED):
			return false
		return _GotmUtility.is_less(a_value, b_value) || _GotmUtility.is_fuzzy_equal(a_value, b_value) && a.path < b.path
