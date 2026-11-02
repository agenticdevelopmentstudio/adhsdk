from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GetShiprConnectionsResponse200ConnectionsItem")


@_attrs_define
class GetShiprConnectionsResponse200ConnectionsItem:
    """
    Attributes:
        id (str):
        label (str):
        account_login (None | str): The GitHub account the app is installed on. This is the register form’s ORG CHOOSER:
            creating a repository under an org needs the app installed there, so an org with no connection is an org the run
            would fail in.
    """

    id: str
    label: str
    account_login: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        label = self.label

        account_login: None | str
        account_login = self.account_login

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "label": label,
                "accountLogin": account_login,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        label = d.pop("label")

        def _parse_account_login(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        account_login = _parse_account_login(d.pop("accountLogin"))

        get_shipr_connections_response_200_connections_item = cls(
            id=id,
            label=label,
            account_login=account_login,
        )

        get_shipr_connections_response_200_connections_item.additional_properties = d
        return get_shipr_connections_response_200_connections_item

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
