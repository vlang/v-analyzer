module bytes

fn test_serialize_deserialize() {
	mut s := Serializer{}
	s.write_string('hello')
	s.write_int(560000)

	mut d := Deserializer{
		data: s.data
	}
	assert d.read_string() == 'hello'
	assert d.read_int() == 560000
}

fn test_serialize_deserialize_several_strings() {
	mut s := Serializer{}
	s.write_string('hello')
	s.write_string('world')

	mut d := Deserializer{
		data: s.data
	}
	assert d.read_string() == 'hello'
	assert d.read_string() == 'world'
}

fn test_serialize_deserialize_stub_element() {
	mut s := Serializer{}
	data := StubBase{
		name: 'test'
		text_range: TextRange{
			line: 1
			column: 2
			end_line: 3
			end_column: 4
		}
		stub_type: .function_declaration
		id: 123456
		text: 'some text with spaces'
		comment: '// comment data'
		receiver: 'Foo'
	}

	serialize_stub_element(mut s, data)

	println(s.data.bytestr())

	mut d := Deserializer{
		data: s.data
	}
	data2 := deserialize_stub_element(mut d)

	assert data2.name == data.name
	assert data2.text_range.line == data.text_range.line
	assert data2.text_range.column == data.text_range.column
	assert data2.text_range.end_line == data.text_range.end_line
	assert data2.text_range.end_column == data.text_range.end_column
	assert data2.stub_type == data.stub_type
	assert data2.id == data.id
	assert data2.text == data.text
	assert data2.comment == data.comment
	assert data2.receiver == data.receiver
}

fn serialize_stub_element(mut s Serializer, stub StubBase) {
	s.write_string(stub.name)
	s.write_int(stub.text_range.line)
	s.write_int(stub.text_range.column)
	s.write_int(stub.text_range.end_line)
	s.write_int(stub.text_range.end_column)
	s.write_u8(u8(stub.stub_type))
	s.write_int(stub.id)
	s.write_string(stub.text)
	s.write_string(stub.comment)
	s.write_string(stub.receiver)
}

fn deserialize_stub_element(mut s Deserializer) StubBase {
	name := s.read_string()
	text_range := TextRange{
		line: s.read_int()
		column: s.read_int()
		end_line: s.read_int()
		end_column: s.read_int()
	}
	stub_type := unsafe { StubType(s.read_u8()) }
	id := s.read_int()
	text := s.read_string()
	comment := s.read_string()
	receiver := s.read_string()

	return StubBase{
		name: name
		text_range: text_range
		stub_type: stub_type
		id: id
		text: text
		comment: comment
		receiver: receiver
	}
}

pub type StubId = int

pub struct StubData {
pub:
	text     string
	comment  string
	receiver string
}

pub struct StubBase {
	StubData
pub:
	name       string
	text_range TextRange
	// stub_list  &StubList
	// parent     &StubElement
	stub_type StubType
pub mut:
	id StubId
}

pub struct TextRange {
pub:
	line       int
	column     int
	end_line   int
	end_column int
}

pub enum StubType as u8 {
	root
	function_declaration
	method_declaration
	receiver
	signature
	struct_declaration
	enum_declaration
	field_declaration
	struct_field_scope
	enum_field_definition
	constant_declaration
	type_alias_declaration
	attributes
	attribute
	attribute_expression
	value_attribute
	plain_type
}
