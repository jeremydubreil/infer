/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package codetoanalyze.java.pulse;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

public class XPathInjection {

  private Document users;

  private static String userControlledString() {
    return InferTaint.inferSecretStringSource();
  }

  private static XPath newXPath() {
    return XPathFactory.newInstance().newXPath();
  }

  // the user-controlled string can close the quotes and change the query, e.g. with "' or '1'='1"
  String evaluateConcatenatedQueryBad() throws Exception {
    String query = "//user[@name='" + userControlledString() + "']/email";
    return newXPath().evaluate(query, users);
  }

  NodeList evaluateWithReturnTypeBad() throws Exception {
    String query = "//user[@name='" + userControlledString() + "']";
    return (NodeList) newXPath().evaluate(query, users, XPathConstants.NODESET);
  }

  String evaluateOnInputSourceBad() throws Exception {
    String query = "//user[@name='" + userControlledString() + "']/email";
    return newXPath().evaluate(query, new InputSource("users.xml"));
  }

  NodeList evaluateExpressionBad() throws Exception {
    String query = "//user[@name='" + userControlledString() + "']";
    return newXPath().evaluateExpression(query, users, NodeList.class);
  }

  String compileThenEvaluateBad() throws Exception {
    XPathExpression expression = newXPath().compile(userControlledString());
    return expression.evaluate(users);
  }

  String formattedQueryBad() throws Exception {
    String query = String.format("//user[@name='%s']/email", userControlledString());
    return newXPath().evaluate(query, users);
  }

  String constantQueryOk() throws Exception {
    return newXPath().evaluate("//user[@name='admin']/email", users);
  }

  // the user-controlled string is bound to the $name variable and cannot change the query
  String variableResolverOk() throws Exception {
    String name = userControlledString();
    XPath xpath = newXPath();
    xpath.setXPathVariableResolver(
        (QName variable) -> variable.getLocalPart().equals("name") ? name : null);
    return xpath.evaluate("//user[@name=$name]/email", users);
  }

  // The check only lets letters and digits through, which cannot change the query. Pulse does not
  // take the result of the check into account.
  String FP_allowListedNameOk() throws Exception {
    String name = userControlledString();
    if (!name.matches("[A-Za-z0-9]+")) {
      throw new IllegalArgumentException("invalid user name");
    }
    return newXPath().evaluate("//user[@name='" + name + "']/email", users);
  }

  // interprocedural

  private String findEmail(String name) throws Exception {
    return newXPath().evaluate("//user[@name='" + name + "']/email", users);
  }

  String findEmailOfUserControlledNameBad() throws Exception {
    return findEmail(userControlledString());
  }

  String findEmailOfConstantNameOk() throws Exception {
    return findEmail("admin");
  }
}
