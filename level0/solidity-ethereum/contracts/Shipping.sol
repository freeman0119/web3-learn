// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.25 <0.9.0;

contract Shipping {
  enum ShippingStatus {
    Pending,
    Shipped,
    Delivered
  }

  ShippingStatus private status;

  event LogNewAlert(string description);

  constructor() {
    status = ShippingStatus.Pending;
  }

  function Shipped() public {
    status = ShippingStatus.Shipped;
    emit LogNewAlert("your package has been shipped");
  }

  function Delivered() public {
    status = ShippingStatus.Delivered;
    emit LogNewAlert("your package has been delivered");
  }

  function getStatus(ShippingStatus _status) internal pure returns (string memory statusText) {
    if (ShippingStatus.Pending == _status) return "Pending";
    if (ShippingStatus.Shipped == _status) return "Shipped";
    if (ShippingStatus.Delivered == _status) return "Delivered";
  }

  function Status() public view returns (string memory) {
    ShippingStatus _status = status;
    return getStatus(_status);
  }
}