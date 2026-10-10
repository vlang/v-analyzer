module types

pub interface TypeVisitor {
mut:
	enter(typ Type) bool
}
