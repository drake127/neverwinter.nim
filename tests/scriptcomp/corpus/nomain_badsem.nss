// EXPECT: 623

// Include-file style script with a semantic error (bad argument type). Plain
// compilation reports "no main" before semantics are checked; with
// SetRequireEntryPoint(FALSE) the semantic pass must still run and flag the
// error instead of silently validating.
void foo(int x)
{
}

void bar()
{
    foo("a");
}