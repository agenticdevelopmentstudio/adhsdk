from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AudienceCampaignsBody")


@_attrs_define
class PostV1AudienceCampaignsBody:
    """
    Attributes:
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        list_ (str): Scopes the call; the caller passes it as a parameter, not in the path.
        from_name (None | str | Unset):
    """

    name: str
    subject: str
    html_body: str
    text_body: str
    list_: str
    from_name: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        list_ = self.list_

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
                "html_body": html_body,
                "text_body": text_body,
                "list": list_,
            }
        )
        if from_name is not UNSET:
            field_dict["from_name"] = from_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("html_body")

        text_body = d.pop("text_body")

        list_ = d.pop("list")

        def _parse_from_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        from_name = _parse_from_name(d.pop("from_name", UNSET))

        post_v1_audience_campaigns_body = cls(
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            list_=list_,
            from_name=from_name,
        )

        post_v1_audience_campaigns_body.additional_properties = d
        return post_v1_audience_campaigns_body

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
