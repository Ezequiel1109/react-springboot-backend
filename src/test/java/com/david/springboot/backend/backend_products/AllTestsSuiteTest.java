package com.david.springboot.backend.backend_products;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;

@RunWith(Suite.class)
@Suite.SuiteClasses({
    UserServicesTest.class,
    ProductControllerMySqlIT.class
})
public class AllTestsSuiteTest {

}
