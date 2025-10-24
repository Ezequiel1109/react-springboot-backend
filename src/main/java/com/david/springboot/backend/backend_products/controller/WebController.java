package com.david.springboot.backend.backend_products.controller;

import org.springframework.web.bind.annotation.*;

@RestController
public class WebController {

    @RequestMapping({"/{path:[^\\.]+}", "/{path:[^\\.]+}/{subpath:[^\\.]+}"})
    
    public String redirect() {
        return "forward:/index.html";
    }

}
