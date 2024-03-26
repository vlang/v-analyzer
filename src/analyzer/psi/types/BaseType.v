module types

pub struct BaseType {
pub:
	module_name string
}

pub fn (s &BaseType) module_name() string {
	return s.module_name
}
