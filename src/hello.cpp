#include "hello.h"

#include <libxml++/libxml++.h>

std::string hello(const std::string& path) {
    xmlpp::DomParser parser;
    parser.parse_file(path);
    return parser.get_document()->get_root_node()->get_name();
}
