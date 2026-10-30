/* Inert example: no constructor and no interception of any CMU function. */
__attribute__((visibility("default")))
int mzd_example_shim_present(void)
{
    return 1;
}
