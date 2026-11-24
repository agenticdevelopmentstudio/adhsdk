from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationTestResultAdoptedSkippedItem")


@_attrs_define
class IntegrationTestResultAdoptedSkippedItem:
    """
    Attributes:
        installation_id (str):
        account_login (str): The account the app is installed on — the org whose repositories it reaches.
        target_type (str): `Organization` or `User`.
        connection_id (str | Unset): The connection holding it — set when this call made one, AND when a previous call
            already had. Adoption is idempotent, so a second call over the same installations reports them connected rather
            than connecting them again.
        skipped (str | Unset): Why it was not connected. Absent on success.
        warning (str | Unset): The connection stands, and the prefetch that rides along behind it — caching what this
            installation was granted — did not finish. NOT a skip: everything that needs a connection works, and only the
            repository picker opening instantly does not. It is reported because this call is what the Test button runs, and
            a picker that will open empty should say so now rather than at the moment somebody needs it.
    """

    installation_id: str
    account_login: str
    target_type: str
    connection_id: str | Unset = UNSET
    skipped: str | Unset = UNSET
    warning: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        installation_id = self.installation_id

        account_login = self.account_login

        target_type = self.target_type

        connection_id = self.connection_id

        skipped = self.skipped

        warning = self.warning

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "installation_id": installation_id,
                "account_login": account_login,
                "target_type": target_type,
            }
        )
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id
        if skipped is not UNSET:
            field_dict["skipped"] = skipped
        if warning is not UNSET:
            field_dict["warning"] = warning

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        installation_id = d.pop("installation_id")

        account_login = d.pop("account_login")

        target_type = d.pop("target_type")

        connection_id = d.pop("connection_id", UNSET)

        skipped = d.pop("skipped", UNSET)

        warning = d.pop("warning", UNSET)

        integration_test_result_adopted_skipped_item = cls(
            installation_id=installation_id,
            account_login=account_login,
            target_type=target_type,
            connection_id=connection_id,
            skipped=skipped,
            warning=warning,
        )

        integration_test_result_adopted_skipped_item.additional_properties = d
        return integration_test_result_adopted_skipped_item

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
