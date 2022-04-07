#ifdef __EMSCRIPTEN__
extern "C" {

int memCardInsert() {
	return 0;
}

int memCardSave() {
	return 0;
}

}
#endif