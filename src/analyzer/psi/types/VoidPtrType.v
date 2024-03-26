module types

pub const voidptr_type = new_voidptr_type()

pub struct VoidPtrType {}

fn new_voidptr_type() &VoidPtrType {
	return &VoidPtrType{}
}

fn (_ &VoidPtrType) name() string {
	return 'voidptr'
}

fn (_ &VoidPtrType) qualified_name() string {
	return 'voidptr'
}

fn (_ &VoidPtrType) readable_name() string {
	return 'voidptr'
}

fn (_ &VoidPtrType) module_name() string {
	return ''
}

pub fn (s &VoidPtrType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}
}

pub fn (s &VoidPtrType) substitute_generics(name_map map[string]Type) Type {
	return s
}
