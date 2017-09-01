package noder

import "bytes"

// Path values represent a noder and its ancestors.  The root goes first
// and the actual final noder the path is refering to will be the last.
//
// A path implements the Noder interface, redirecting all the interface
// calls to its final noder.
//
// Paths build from an empty Noder slice are not valid paths and should
// not be used.
type Path []Noder

// String returns the full path of the final noder as a string, using
// "/" as the separator.
func (p Path) String() string {
	var buf bytes.Buffer
	sep := ""
	for _, e := range p {
		_, _ = buf.WriteString(sep)
		sep = "/"
		_, _ = buf.WriteString(e.Name())
	}

	return buf.String()
}

// Last returns the final noder in the path.
func (p Path) Last() Noder {
	return p[len(p)-1]
}

// Hash returns the hash of the final noder of the path.
func (p Path) Hash() []byte {
	return p.Last().Hash()
}

// Name returns the name of the final noder of the path.
func (p Path) Name() string {
	return p.Last().Name()
}

// IsDir returns if the final noder of the path is a directory-like
// noder.
func (p Path) IsDir() bool {
	return p.Last().IsDir()
}

// Children returns the children of the final noder in the path.
func (p Path) Children() ([]Noder, error) {
	return p.Last().Children()
}

// NumChildren returns the number of children the final noder of the
// path has.
func (p Path) NumChildren() (int, error) {
	return p.Last().NumChildren()
}
