module kernel::types;

fn void test_string() @test {
    String str = "Hello World!";

    assert(str.len == 12, "str has 12 characters");
}