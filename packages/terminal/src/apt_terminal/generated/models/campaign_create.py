from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="CampaignCreate")


@_attrs_define
class CampaignCreate:
    """
    Attributes:
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        from_name (None | str | Unset):
    """

    name: str
    subject: str
    html_body: str
    text_body: str
    from_name: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        from_name: None | str | Unset
        if isinstance(self.from_name, Unset):
            from_name = UNSET
        else:
            from_name = self.from_name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "subject": subject,
                "htmlBody": html_body,
                "textBody": text_body,
            }
        )
        if from_name is not UNSET:
            field_dict["fromName"] = from_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("htmlBody")

        text_body = d.pop("textBody")

        def _parse_from_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        from_name = _parse_from_name(d.pop("fromName", UNSET))

        campaign_create = cls(
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            from_name=from_name,
        )

        campaign_create.additional_properties = d
        return campaign_create

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
