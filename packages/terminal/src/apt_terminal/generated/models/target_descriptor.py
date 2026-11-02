from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="TargetDescriptor")


@_attrs_define
class TargetDescriptor:
    """
    Attributes:
        kind (str): the target's registry, e.g. 'content.markdown'
        id (str): the opaque target id
        title (str): the row's display title; never empty
        subtitle (None | str): one supporting line, or null
        url (None | str): set only when the target is a link OUT of the platform (a saved URL)
    """

    kind: str
    id: str
    title: str
    subtitle: None | str
    url: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind

        id = self.id

        title = self.title

        subtitle: None | str
        subtitle = self.subtitle

        url: None | str
        url = self.url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "id": id,
                "title": title,
                "subtitle": subtitle,
                "url": url,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = d.pop("kind")

        id = d.pop("id")

        title = d.pop("title")

        def _parse_subtitle(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subtitle = _parse_subtitle(d.pop("subtitle"))

        def _parse_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        url = _parse_url(d.pop("url"))

        target_descriptor = cls(
            kind=kind,
            id=id,
            title=title,
            subtitle=subtitle,
            url=url,
        )

        target_descriptor.additional_properties = d
        return target_descriptor

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
