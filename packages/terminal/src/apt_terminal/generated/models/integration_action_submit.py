from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionSubmit")


@_attrs_define
class IntegrationActionSubmit:
    """actionType=submit — a Reddit-style subreddit submission; exactly one of url (link post) or non-empty text (self
    post) is required (an empty-string text counts as absent)

        Attributes:
            subreddit (str): Subreddit name without the r/ prefix
            title (str):
            url (str | Unset): Link post target (mutually exclusive with text)
            text (str | Unset): Self-post body (mutually exclusive with url)
    """

    subreddit: str
    title: str
    url: str | Unset = UNSET
    text: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subreddit = self.subreddit

        title = self.title

        url = self.url

        text = self.text

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subreddit": subreddit,
                "title": title,
            }
        )
        if url is not UNSET:
            field_dict["url"] = url
        if text is not UNSET:
            field_dict["text"] = text

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subreddit = d.pop("subreddit")

        title = d.pop("title")

        url = d.pop("url", UNSET)

        text = d.pop("text", UNSET)

        integration_action_submit = cls(
            subreddit=subreddit,
            title=title,
            url=url,
            text=text,
        )

        integration_action_submit.additional_properties = d
        return integration_action_submit

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
